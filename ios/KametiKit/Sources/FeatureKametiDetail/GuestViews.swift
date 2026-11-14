import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

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
            : String(localized: "Invite them so they can see their payments.", bundle: .module)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: KSpace.md) {
                Image(systemName: "person.badge.clock")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(KColors.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).kText(KTextToken.bodyStrong, color: KColors.warning)
                    Text(subtitle).kText(KTextToken.bodySm, color: KColors.warning)
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
        Label(title, systemImage: "message.fill")
            .kText(KTextStyle(size: prominent ? 15 : 13, weight: .semibold), color: prominent ? KColors.textOnBrand : KColors.positive)
            .padding(.horizontal, KSpace.md)
            .frame(maxWidth: prominent ? .infinity : nil, minHeight: prominent ? 44 : 36)
            .background(prominent ? AnyShapeStyle(KColors.brand) : AnyShapeStyle(Color.clear), in: RoundedRectangle(cornerRadius: prominent ? 12 : 18))
            .overlay(RoundedRectangle(cornerRadius: prominent ? 12 : 18).strokeBorder(prominent ? KColors.brand : KColors.positive.opacity(0.4)))
            .contentShape(RoundedRectangle(cornerRadius: prominent ? 12 : 18))
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
