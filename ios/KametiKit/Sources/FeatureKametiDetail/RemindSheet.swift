import Foundation
import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// The text and WhatsApp link for reminding someone who doesn't have the app (FR-84).
enum ReminderLogic {
    static func text(name: String, owed: Money, kameti: String, dueDay: Int) -> String {
        String(localized: "Hi \(MemberLogic.firstName(name)), a reminder that \(owed.format()) for \(kameti) is due by the \(ordinal(dueDay)). Thank you!", bundle: .module)
    }

    /// "0300 1234567" → wa.me/923001234567 with the message; no phone → nil (use the share sheet).
    static func whatsAppURL(phone: String?, text: String) -> URL? {
        guard let phone else { return nil }
        var digits = phone.filter(\.isNumber)
        if digits.hasPrefix("00") { digits.removeFirst(2) }
        if digits.hasPrefix("0") { digits = "92" + digits.dropFirst() }
        guard digits.count >= 10 else { return nil }
        var parts = URLComponents(string: "https://wa.me/\(digits)")
        parts?.queryItems = [URLQueryItem(name: "text", value: text)]
        return parts?.url
    }

    static func ordinal(_ day: Int) -> String {
        let suffix = (11...13).contains(day % 100) ? "th" : ([1: "st", 2: "nd", 3: "rd"][day % 10] ?? "th")
        return "\(day)\(suffix)"
    }
}

/// Owner's "Remind members who owe" (FR-82): a push to everyone with the app,
/// once a day, with an optional message; WhatsApp for the rest (FR-84).
struct RemindSheet: View {
    let kameti: Kameti
    let dependencies: KametiDependencies
    /// From a member's sheet: just that person.
    var onlyMemberId: String?
    let onDone: () -> Void

    @State private var targets: ReminderTargets?
    @State private var selected: Set<String> = []
    @State private var message = ""
    @State private var isBusy = false
    @State private var failure: Failure?
    @State private var sent: ReminderResult?

    private var withApp: [ReminderTargets.Member] { targets?.members.filter(\.hasApp) ?? [] }
    private var withoutApp: [ReminderTargets.Member] { targets?.members.filter { !$0.hasApp } ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                if let targets {
                    if let sent {
                        VStack(alignment: .leading, spacing: KSpace.xs) {
                            Label(sent.sent == 1 ? String(localized: "Reminder sent to 1 member.", bundle: .module)
                                                 : String(localized: "Reminder sent to \(sent.sent) members.", bundle: .module),
                                  systemImage: "checkmark.circle.fill")
                                .kText(KTextToken.bodyStrong, color: KColors.positive)
                            if !sent.skipped.isEmpty {
                                Text("\(ListFormatter.localizedString(byJoining: sent.skipped)) already had a reminder today.", bundle: .module)
                                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
                            }
                        }
                    } else if !withApp.isEmpty, withApp.allSatisfy(\.remindedToday) {
                        note(String(localized: "You've already reminded everyone here today. You can remind them again tomorrow.", bundle: .module), tint: KColors.info, background: KColors.infoSubtle)
                    }
                    if !withApp.isEmpty { appSection(targets) }
                    if !withoutApp.isEmpty { whatsAppSection(targets) }
                    if targets.members.isEmpty {
                        ContentUnavailableView(onlyMemberId == nil ? String(localized: "Nobody owes right now", bundle: .module)
                                                                   : String(localized: "Nothing owed right now", bundle: .module),
                                               systemImage: "checkmark.seal")
                    }
                    if let failure {
                        Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
                    }
                } else if let failure {
                    KMessageCard(String(localized: "Couldn't load who owes", bundle: .module), message: failure.helpMessage,
                                 actionTitle: String(localized: "Try again", bundle: .module)) { Task { await load() } }
                } else {
                    KSkeletonRows(rows: 3)
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xxs)
            .padding(.bottom, KSpace.xl)
        }
        .kDismissesKeyboard()
        .task { await load() }
    }

    // MARK: Sections

    @ViewBuilder private func appSection(_ targets: ReminderTargets) -> some View {
        let canSend = sent == nil && withApp.contains { !$0.remindedToday }
        VStack(alignment: .leading, spacing: KSpace.sm) {
            label(String(localized: "In the app · they get a notification", bundle: .module))
            VStack(spacing: 0) {
                ForEach(Array(withApp.enumerated()), id: \.element.id) { index, member in
                    Button {
                        if selected.contains(member.id) { selected.remove(member.id) } else { selected.insert(member.id) }
                    } label: {
                        row(member, last: index == withApp.count - 1) {
                            if member.remindedToday {
                                Text("Reminded today", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
                            } else {
                                Image(systemName: selected.contains(member.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(selected.contains(member.id) ? KColors.brand : KColors.borderStrong)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend || member.remindedToday)
                }
            }
            .padding(.horizontal, KSpace.lg)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: 16))
        }
        if canSend {
            VStack(alignment: .leading, spacing: 6) {
                label(String(localized: "Message (optional)", bundle: .module))
                TextField(String(localized: "Rs … is due by the \(ReminderLogic.ordinal(targets.dueDay)) · \(kameti.name)", bundle: .module), text: $message, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(KSpace.md)
                    .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.border))
                Text("Each person sees what they owe unless you write your own. You can remind each person once a day.", bundle: .module)
                    .kText(KTextToken.caption, color: KColors.textSecondary)
            }
            Button(action: send) {
                ZStack {
                    Text(selected.count == 1 ? String(localized: "Send reminder to 1", bundle: .module)
                                             : String(localized: "Send reminder to \(selected.count)", bundle: .module))
                        .opacity(isBusy ? 0 : 1)
                    if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                }
                .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            .disabled(selected.isEmpty)
            .allowsHitTesting(!isBusy)
        }
    }

    private func whatsAppSection(_ targets: ReminderTargets) -> some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            label(String(localized: "Without the app · remind on WhatsApp", bundle: .module))
            VStack(spacing: 0) {
                ForEach(Array(withoutApp.enumerated()), id: \.element.id) { index, member in
                    let text = ReminderLogic.text(name: member.name, owed: member.owed, kameti: kameti.name, dueDay: targets.dueDay)
                    row(member, last: index == withoutApp.count - 1) {
                        if let url = ReminderLogic.whatsAppURL(phone: member.phone, text: text) {
                            Link(destination: url) { whatsAppLabel }
                        } else {
                            ShareLink(item: text) { whatsAppLabel }
                        }
                    }
                }
            }
            .padding(.horizontal, KSpace.lg)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var whatsAppLabel: some View {
        Label(String(localized: "WhatsApp", bundle: .module), systemImage: "message.fill")
            .kText(KTextStyle(size: 13, weight: .semibold), color: KColors.positive)
            .padding(.horizontal, KSpace.md).frame(minHeight: 36)
            .overlay(Capsule().strokeBorder(KColors.positive.opacity(0.4)))
            .contentShape(Capsule())
    }

    private func row<Trailing: View>(_ member: ReminderTargets.Member, last: Bool, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: KSpace.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).kText(KTextToken.bodyStrong)
                Text(String(localized: "Owes \(member.owed.format())", bundle: .module)).kText(KTextToken.bodySm, color: KColors.warning)
            }
            Spacer(minLength: KSpace.sm)
            trailing()
        }
        .padding(.vertical, KSpace.md)
        .overlay(alignment: .bottom) { if !last { Divider() } }
        .contentShape(Rectangle())
    }

    private func label(_ text: String) -> some View {
        Text(text).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
    }

    private func note(_ text: String, tint: Color, background: Color) -> some View {
        Label(text, systemImage: "info.circle")
            .kText(KTextToken.bodySm, color: tint)
            .padding(KSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Actions

    private func load() async {
        failure = nil
        do throws(Failure) {
            var loaded = try await dependencies.notifications.reminderTargets(kametiId: kameti.id)
            if let onlyMemberId {
                loaded = ReminderTargets(dueDay: loaded.dueDay, members: loaded.members.filter { $0.memberId == onlyMemberId })
            }
            targets = loaded
            selected = Set(loaded.members.filter { $0.hasApp && !$0.remindedToday }.map(\.id))
        } catch {
            failure = error
        }
    }

    private func send() {
        kDismissKeyboard()
        isBusy = true
        failure = nil
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = Set(withApp.filter { !$0.remindedToday }.map(\.id))
        Task {
            do throws(Failure) {
                sent = try await dependencies.notifications.sendReminder(
                    kametiId: kameti.id, message: trimmed.isEmpty ? nil : trimmed,
                    memberIds: selected == all ? nil : Array(selected)
                )
            } catch {
                failure = error
            }
            isBusy = false
        }
    }
}
