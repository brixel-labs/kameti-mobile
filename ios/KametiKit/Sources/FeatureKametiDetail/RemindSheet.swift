import Foundation
import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// The text and WhatsApp link for reminding someone who doesn't have the app (FR-84).
enum ReminderLogic {
    static func text(name: String, owed: Money, kameti: String, dueDay: Int) -> String {
        String(localized: "Assalam O Alaikum \(MemberLogic.firstName(name)), a reminder that \(owed.format()) for \(kameti) is due by the \(ordinal(dueDay)). Thank you!", bundle: .module)
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

/// Owner's "Remind members who owe" (FR-82, FR-84): everyone who owes in one
/// list, each with the one action that suits them: a notification for people
/// with the app (once a day each, with an optional message), WhatsApp for the rest.
struct RemindSheet: View {
    let kameti: Kameti
    /// The kameti's people, slots and dues, for each person's row.
    let data: KametiDetailData
    let dependencies: KametiDependencies
    /// From a member's sheet: just that person.
    var onlyMemberId: String?
    let onDone: () -> Void

    @State private var targets: ReminderTargets?
    @State private var message = ""
    @State private var notifyingId: String?
    @State private var sentIds: Set<String> = []
    @State private var alreadyIds: Set<String> = []
    @State private var failure: Failure?

    private var members: [ReminderTargets.Member] { targets?.members ?? [] }
    private var canNotifyAny: Bool { members.contains { $0.hasApp && !isReminded($0) } }

    private func isReminded(_ member: ReminderTargets.Member) -> Bool {
        member.remindedToday || alreadyIds.contains(member.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                if let targets {
                    if onlyMemberId == nil, !members.isEmpty {
                        Text(summary).kText(KTextToken.body, color: KColors.textSecondary)
                            .padding(.bottom, -KSpace.sm)
                    }
                    if !members.isEmpty {
                        list(targets)
                        Text("Members with the app get a notification instead.", bundle: .module)
                            .kText(KTextToken.caption, color: KColors.textSecondary)
                            .padding(.top, -KSpace.sm)
                    }
                    if canNotifyAny { messageField(targets) }
                    if members.isEmpty {
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

    /// "2 owe Rs 3,50,000".
    private var summary: String {
        let total = members.reduce(Money.zero) { $0 + $1.owed }
        return String(localized: "\(members.count) owe \(total.format())", bundle: .module)
    }

    // MARK: List

    private func list(_ targets: ReminderTargets) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                row(member, last: index == members.count - 1) {
                    if member.hasApp { appAction(member) } else { whatsAppAction(member, targets) }
                }
            }
        }
    }

    @ViewBuilder private func appAction(_ member: ReminderTargets.Member) -> some View {
        if sentIds.contains(member.id) {
            Label(String(localized: "Sent", bundle: .module), systemImage: "checkmark.circle.fill")
                .kText(KTextToken.caption, color: KColors.positive)
        } else if isReminded(member) {
            Text("Reminded today", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
        } else {
            Button { notify(member) } label: {
                ZStack {
                    Label(String(localized: "Notify", bundle: .module), systemImage: "bell")
                        .opacity(notifyingId == member.id ? 0 : 1)
                    if notifyingId == member.id { ProgressView().controlSize(.small).tint(KColors.brand) }
                }
                .kText(KTextStyle(size: 12, weight: .semibold), color: KColors.brand)
                .padding(.horizontal, KSpace.md).frame(minHeight: 30)
                .overlay(Capsule().strokeBorder(KColors.brand.opacity(0.4)))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .allowsHitTesting(notifyingId == nil)
        }
    }

    @ViewBuilder private func whatsAppAction(_ member: ReminderTargets.Member, _ targets: ReminderTargets) -> some View {
        let text = ReminderLogic.text(name: member.name, owed: member.owed, kameti: kameti.name, dueDay: targets.dueDay)
        if let url = ReminderLogic.whatsAppURL(phone: member.phone, text: text) {
            Link(destination: url) { whatsAppLabel }
        } else {
            ShareLink(item: text) { whatsAppLabel }
        }
    }

    private var whatsAppLabel: some View {
        HStack(spacing: KSpace.xs) {
            KIcon.whatsApp(size: 15)
            Text("WhatsApp", bundle: .module)
        }
        .kText(KTextStyle(size: 12, weight: .semibold), color: KColors.positive)
        .padding(.horizontal, KSpace.md).frame(minHeight: 30)
        .overlay(Capsule().strokeBorder(KColors.positive.opacity(0.4)))
        .contentShape(Capsule())
    }

    private func messageField(_ targets: ReminderTargets) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label(String(localized: "Notification message (optional)", bundle: .module))
            TextField(String(localized: "Rs … is due by the \(ReminderLogic.ordinal(targets.dueDay)) · \(kameti.name)", bundle: .module), text: $message, axis: .vertical)
                .lineLimit(2...4)
                .padding(KSpace.md)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.border))
        }
    }

    /// A list row like the Members tab's (avatar, name, a line under it, a divider),
    /// with what they owe under the name and the action on the right.
    private func row<Trailing: View>(_ member: ReminderTargets.Member, last: Bool, @ViewBuilder trailing: () -> Trailing) -> some View {
        let person = data.members.first { $0.id == member.memberId }
        let colorIndex = person.flatMap { Int($0.color ?? "") } ?? max(person.flatMap { data.members.firstIndex(of: $0) } ?? 0, 0)
        return VStack(spacing: 0) {
            HStack(spacing: KSpace.md) {
                KAvatar(name: member.name, colorIndex: colorIndex, size: .medium)
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name).kText(KTextToken.bodyStrong)
                    Text(String(localized: "Owes \(member.owed.format())", bundle: .module)).kText(KTextToken.bodySm, color: KColors.warning)
                }
                Spacer(minLength: KSpace.sm)
                trailing()
            }
            .padding(.vertical, KSpace.md)
            if !last { Divider() }
        }
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
        } catch {
            failure = error
        }
    }

    /// One person's notification, with the optional message.
    private func notify(_ member: ReminderTargets.Member) {
        kDismissKeyboard()
        notifyingId = member.id
        failure = nil
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do throws(Failure) {
                let result = try await dependencies.notifications.sendReminder(
                    kametiId: kameti.id, message: trimmed.isEmpty ? nil : trimmed, memberIds: [member.id]
                )
                if result.sent > 0 { sentIds.insert(member.id) } else { alreadyIds.insert(member.id) }
            } catch {
                failure = error
            }
            notifyingId = nil
        }
    }
}
