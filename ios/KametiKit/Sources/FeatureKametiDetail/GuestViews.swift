import KametiCore
import KametiDomain
import KametiUI
import SwiftUI
import UIKit

/// "Waiting for Ali to join" / "3 of 9 haven't joined yet": the prominent card at the top of the
/// owner's Overview while anyone hasn't joined. The whole card opens the Members tab.
struct SetupCard: View {
    let progress: SetupProgress
    let action: () -> Void

    private var title: String {
        if progress.waiting.count == 1, let member = progress.waiting.first {
            return String(localized: "Waiting for \(member.name) to join", bundle: .module)
        }
        return String(localized: "\(progress.waiting.count) of \(progress.expected) haven't joined yet", bundle: .module)
    }

    private var subtitle: String {
        progress.needsApproval
            ? String(localized: "Someone is waiting for your approval.", bundle: .module)
            : String(localized: "Invite them to see their payments.", bundle: .module)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: KSpace.md) {
                Image(systemName: "person.badge.clock")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(KColors.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).kText(KTextToken.bodyStrong, color: KColors.warning)
                    Text(subtitle).kText(KTextToken.bodySm, color: KColors.warning).lineLimit(1).minimumScaleFactor(0.85)
                }
                Spacer(minLength: KSpace.sm)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(KColors.warning)
            }
            .padding(KSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: KRadius.card))
            .contentShape(RoundedRectangle(cornerRadius: KRadius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// Opens WhatsApp with the message for a member who isn't on the app, or the share sheet when they
/// have no usable phone number (or WhatsApp isn't there).
struct GuestMessageButton: View {
    let title: String
    let text: String
    let phone: String?
    var prominent = false

    var body: some View {
        if let url = ReminderLogic.whatsAppURL(phone: phone, text: text) {
            Link(destination: url) { label }
        } else {
            ShareLink(item: text) { label }
        }
    }

    private var label: some View {
        Label(title, systemImage: prominent ? "arrowshape.turn.up.right" : "message.fill")
            .kText(KTextStyle(size: prominent ? 15 : 13, weight: .semibold), color: prominent ? KColors.textOnBrand : KColors.positive)
            .padding(.horizontal, KSpace.md)
            .frame(maxWidth: prominent ? .infinity : nil, minHeight: prominent ? 44 : 36)
            .background(prominent ? AnyShapeStyle(KColors.brand) : AnyShapeStyle(Color.clear), in: Capsule())
            .overlay(Capsule().strokeBorder(prominent ? KColors.brand : KColors.positive.opacity(0.4)))
            .contentShape(Capsule())
    }
}

/// Right after a payment for someone who isn't on the app: a receipt ready to send on WhatsApp.
/// One row per person (tap-to-settle can record several), and an easy way out.
struct ReceiptSheet: View {
    let data: KametiDetailData
    let receipts: [PendingReceipt]
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                Text("They don't use the app, so send them a receipt.", bundle: .module)
                    .kText(KTextToken.body, color: KColors.textSecondary)
                VStack(spacing: 0) {
                    ForEach(Array(receipts.enumerated()), id: \.element.id) { index, receipt in
                        if let member = data.members.first(where: { $0.id == receipt.memberId }) {
                            HStack(spacing: KSpace.md) {
                                KAvatar(name: member.name, colorIndex: DetailRow<KAvatar, EmptyView>.colorIndex(of: member, in: data.members), size: .medium)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name).kText(KTextToken.bodyStrong)
                                    Text(receipt.amount.format()).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                                }
                                Spacer(minLength: KSpace.sm)
                                GuestMessageButton(
                                    title: String(localized: "WhatsApp", bundle: .module),
                                    text: GuestUpdate.text(for: member, in: data, receipt: receipt),
                                    phone: MemberLogic.contact(of: member, in: data)?.phone
                                )
                            }
                            .padding(.vertical, KSpace.md)
                            if index < receipts.count - 1 { Divider() }
                        }
                    }
                }
                .padding(.horizontal, KSpace.lg)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
                Button(action: onDone) {
                    Text("Not now", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xxs)
            .padding(.bottom, KSpace.xl)
        }
    }
}

/// The system share sheet, for a guest with no phone number (or no WhatsApp).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// One tap from a list: makes the guest's view-only link if there is none, then opens WhatsApp (or the
/// share sheet without a phone number) with their update and the link.
struct GuestQuickSend: View {
    let member: Member
    let data: KametiDetailData
    let model: KametiDetailViewModel
    var style = Style.tonal

    /// `tonal` is the capsule in the Guests card; `plain` is the text link under a name in a list.
    enum Style { case tonal, plain }

    @Environment(\.openURL) private var openURL
    @State private var busy = false
    @State private var shared: SharedText?

    private struct SharedText: Identifiable {
        let id = UUID()
        let text: String
    }

    var body: some View {
        Button(action: send) {
            ZStack {
                Label(String(localized: "Share update", bundle: .module), systemImage: "arrowshape.turn.up.right").opacity(busy ? 0 : 1)
                if busy { ProgressView().controlSize(.small) }
            }
            .kText(KTextStyle(size: style == .tonal ? 13 : 14, weight: .semibold), color: KColors.positive)
            .padding(.horizontal, style == .tonal ? KSpace.md : 0)
            .frame(minHeight: 34)
            .background(style == .tonal ? KColors.positiveSubtle : Color.clear, in: Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .accessibilityLabel(Text("Share an update with \(MemberLogic.firstName(member.name))", bundle: .module))
        .sheet(item: $shared) { ShareSheet(items: [$0.text]).presentationDetents([.medium, .large]) }
    }

    private func send() {
        busy = true
        Task {
            let link = await model.ensureViewLink(memberId: member.id)
            let text = GuestUpdate.text(for: member, in: data, viewLink: link?.link)
            if let url = ReminderLogic.whatsAppURL(phone: MemberLogic.contact(of: member, in: data)?.phone, text: text) {
                openURL(url)
            } else {
                shared = SharedText(text: text)
            }
            busy = false
        }
    }
}

/// Overview: the people who don't use the app, each with a one-tap update, so sending one never means
/// going Members, tap a person, Send update.
struct GuestsCard: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel
    @State private var showsAll = false

    /// Most useful first: the ones who owe, biggest amount first, then everyone else.
    private var guests: [Member] {
        let all = data.members.filter { if case .guest = AccessState.of($0, in: data) { return true } else { return false } }
        func owes(_ m: Member) -> Int { data.balances.first { $0.memberId == m.id }?.owes.rupees ?? 0 }
        return all.sorted { owes($0) > owes($1) }
    }

    /// How many show before "Show all": the card never pushes the month card off the screen.
    private static let collapsed = 2

    var body: some View {
        let guests = guests
        if !guests.isEmpty {
            let shown = showsAll ? guests : Array(guests.prefix(Self.collapsed))
            VStack(alignment: .leading, spacing: KSpace.sm) {
                Text(guests.count > 1 ? String(localized: "Guests · \(guests.count)", bundle: .module) : String(localized: "Guests", bundle: .module))
                    .kText(KTextToken.bodyStrong)
                Text("They don't use the app. Share an update with them.", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
                VStack(spacing: 0) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, member in
                        HStack(spacing: KSpace.md) {
                            KAvatar(name: member.name, colorIndex: DetailRow<KAvatar, EmptyView>.colorIndex(of: member, in: data.members), size: .medium)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name).kText(KTextToken.bodyStrong).lineLimit(1)
                                Text(GuestUpdate.statusLine(for: member, in: data)).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                            }
                            Spacer(minLength: KSpace.sm)
                            GuestQuickSend(member: member, data: data, model: model)
                        }
                        .padding(.vertical, KSpace.sm)
                        if index < shown.count - 1 || guests.count > Self.collapsed { Divider() }
                    }
                    if guests.count > Self.collapsed {
                        Button { withAnimation(.smooth(duration: 0.25)) { showsAll.toggle() } } label: {
                            HStack {
                                Text(showsAll ? String(localized: "Show fewer", bundle: .module) : String(localized: "Show all \(guests.count) guests", bundle: .module))
                                    .kText(KTextToken.bodyStrong, color: KColors.brand)
                                Spacer()
                                Image(systemName: showsAll ? "chevron.up" : "chevron.down").font(.system(size: 13, weight: .semibold)).foregroundStyle(KColors.brand)
                            }
                            .frame(minHeight: 40)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(KSpace.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
            .overlay(RoundedRectangle(cornerRadius: KRadius.card).strokeBorder(KColors.border))
        }
    }
}
