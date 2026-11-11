import FeatureInvites
import KametiCore
import KametiDomain
import KametiUI
import SwiftUI
import UIKit

/// Where a member stands with the app, worked out from their join status and
/// invites. Kept apart from the view so it can be tested.
enum AccessState: Equatable {
    /// The owner's own member row: nothing to invite.
    case owner
    case joined
    case needsApproval(invitedEmail: String?, acceptedEmail: String?)
    case invited(Invite)
    /// Not invited, declined or revoked. `email` is where an invite would go.
    case notInvited(email: String?, declined: Bool)

    static func of(_ member: Member, in data: KametiDetailData) -> AccessState {
        if member.profileId == data.userId { return .owner }
        let mine = data.invites.filter { $0.memberId == member.id }
        switch member.joinStatus {
        case .joined:
            return .joined
        case .pendingApproval:
            let accepted = mine.first { $0.status == .accepted }
            return .needsApproval(invitedEmail: accepted?.email, acceptedEmail: accepted?.acceptedEmail)
        case .invited:
            if let live = mine.first(where: { $0.status == .pending }) { return .invited(live) }
            return .notInvited(email: MemberLogic.contact(of: member, in: data)?.email, declined: false)
        case .notInvited, .declined:
            return .notInvited(email: MemberLogic.contact(of: member, in: data)?.email, declined: member.joinStatus == .declined)
        }
    }

    /// Members "Invite all" would invite: not invited yet, with an email.
    static func invitable(in data: KametiDetailData) -> [Member] {
        data.members.filter {
            if case .notInvited(let email, _) = of($0, in: data) { return email != nil }
            return false
        }
    }
}

/// App access (board AI-1a): invite status, the code and link to share, and
/// Send / Resend / Revoke; Review join when someone is waiting for approval;
/// Remove access once they've joined.
struct AppAccessCard: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel
    let member: Member

    @State private var busy = false
    @State private var failure: Failure?
    @State private var confirmingRevoke = false
    @State private var confirmingUnlink = false
    @State private var reviewing = false
    @State private var copied = false

    private var state: AccessState { AccessState.of(member, in: data) }
    private var sent: KametiDetailViewModel.SentInvite? { model.sentInvites[member.id] }
    private var firstName: String { MemberLogic.firstName(member.name) }

    var body: some View {
        if state != .owner {
            VStack(alignment: .leading, spacing: KSpace.md) {
                HStack {
                    Text("App access", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
                    Spacer()
                    statusPill
                }
                content
                if let failure {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                        .kText(KTextToken.bodySm, color: KColors.negative)
                }
            }
            .padding(KSpace.lg)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(KColors.border))
            .alert(String(localized: "Revoke \(firstName)'s invite?", bundle: .module), isPresented: $confirmingRevoke) {
                Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
                Button(String(localized: "Revoke", bundle: .module), role: .destructive) { run { await model.revokeInvite(memberId: member.id) } }
            } message: {
                Text("The link and code stop working. You can send a new invite later.", bundle: .module)
            }
            .alert(String(localized: "Remove \(firstName)'s app access?", bundle: .module), isPresented: $confirmingUnlink) {
                Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
                Button(String(localized: "Remove access", bundle: .module), role: .destructive) { run { await model.unlinkMember(memberId: member.id) } }
            } message: {
                Text("\(firstName) stops seeing this kameti in the app. Their payments and history stay, and you can invite them again later.", bundle: .module)
            }
            .kBottomSheet(isPresented: $reviewing, title: String(localized: "Join request", bundle: .module), detents: [.large]) {
                if case .needsApproval(let invited, let accepted) = state {
                    ApproveJoinSheet(
                        memberName: member.name, invitedEmail: invited, acceptedEmail: accepted,
                        approve: { await model.approveJoin(memberId: member.id) },
                        reject: { await model.declineJoin(memberId: member.id) },
                        onDone: { reviewing = false }
                    )
                }
            }
        }
    }

    // MARK: Pieces

    @ViewBuilder private var statusPill: some View {
        switch state {
        case .owner: EmptyView()
        case .joined:
            KPill(String(localized: "Joined", bundle: .module), foreground: KColors.positive, background: KColors.positiveSubtle)
        case .needsApproval:
            KPill(String(localized: "Needs approval", bundle: .module), foreground: KColors.info, background: KColors.infoSubtle)
        case .invited(let invite) where invite.deliveryStatus?.didNotArrive == true && sent == nil:
            KPill(String(localized: "Email bounced", bundle: .module), symbol: "exclamationmark.triangle.fill",
                  foreground: KColors.negative, background: KColors.negativeSubtle)
        case .invited(let invite):
            KPill(
                String(localized: "Invited · \(InviteLogic.expiryText(invite.expiresAt, now: model.now))", bundle: .module),
                foreground: KColors.warning, background: KColors.warningSubtle
            )
        case .notInvited(_, let declined):
            declined
                ? KPill(String(localized: "Declined", bundle: .module), foreground: KColors.negative, background: KColors.negativeSubtle)
                : KPill(String(localized: "Not invited", bundle: .module), foreground: KColors.textSecondary, background: KColors.surfaceSunken)
        }
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .owner:
            EmptyView()
        case .joined:
            HStack(alignment: .center, spacing: KSpace.md) {
                note(String(localized: "\(firstName) can see this kameti in the app.", bundle: .module))
                Spacer(minLength: 0)
                if data.kameti.status != .archived { unlinkButton }
            }
        case .needsApproval:
            note(String(localized: "\(firstName) accepted with a different email. Check it's really them before they can see anything.", bundle: .module))
            actionButton(String(localized: "Review join", bundle: .module), symbol: "person.badge.clock", prominent: true) { reviewing = true }
        case .invited(let invite):
            if let sent {
                note(sent.emailed
                     ? String(localized: "Emailed to \(sent.link.email ?? invite.email ?? ""). They can also join with this code:", bundle: .module)
                     : String(localized: "Email isn't set up yet, so share the link, or this code, with \(firstName):", bundle: .module))
                codeBox(sent.link.code)
                HStack(spacing: KSpace.sm) {
                    ShareLink(item: shareText(sent.link)) {
                        smallLabel(String(localized: "Share link", bundle: .module), symbol: "square.and.arrow.up", prominent: true)
                    }
                    .buttonStyle(.plain)
                    resendButton
                    revokeButton
                }
            } else if invite.deliveryStatus?.didNotArrive == true {
                // E39b: the email didn't arrive; a resend gives a new code and link to share by hand.
                note(String(localized: "The invite email to \(invite.email ?? "") didn't arrive. Check the address above, or resend to get a new code and link to share on WhatsApp.", bundle: .module))
                HStack(spacing: KSpace.sm) {
                    resendButton
                    revokeButton
                }
            } else {
                note(invite.deliveryStatus == .delivered
                     ? String(localized: "Delivered to \(invite.email ?? ""). The code is only shown when an invite is sent; resend to get a new one.", bundle: .module)
                     : String(localized: "Sent to \(invite.email ?? ""). The code is only shown when an invite is sent; resend to get a new one.", bundle: .module))
                HStack(spacing: KSpace.sm) {
                    resendButton
                    revokeButton
                }
            }
        case .notInvited(let email, _):
            if let email {
                note(String(localized: "Send \(firstName) an invite to see this kameti in the app. It goes to \(email).", bundle: .module))
                actionButton(String(localized: "Send invite", bundle: .module), symbol: "paperplane", prominent: true) {
                    run { await model.invite(memberId: member.id) }
                }
            } else {
                note(String(localized: "Add an email above and save, then you can invite \(firstName).", bundle: .module))
            }
        }
    }

    private var resendButton: some View {
        Button { run { await model.invite(memberId: member.id, resend: true) } } label: {
            smallLabel(String(localized: "Resend", bundle: .module), symbol: "arrow.clockwise", prominent: false)
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private var unlinkButton: some View {
        Button { confirmingUnlink = true } label: {
            Text("Remove access", bundle: .module).kText(KTextStyle(size: 13, weight: .semibold), color: KColors.negative)
                .padding(.horizontal, KSpace.md).frame(minHeight: 36)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(KColors.negative.opacity(0.35)))
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private var revokeButton: some View {
        Button { confirmingRevoke = true } label: {
            Text("Revoke", bundle: .module).kText(KTextStyle(size: 13, weight: .semibold), color: KColors.negative)
                .padding(.horizontal, KSpace.md).frame(minHeight: 36)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(KColors.negative.opacity(0.35)))
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private func note(_ text: String) -> some View {
        Text(text).kText(KTextToken.bodySm, color: KColors.textSecondary).fixedSize(horizontal: false, vertical: true)
    }

    private func codeBox(_ code: String) -> some View {
        HStack {
            Text(code).kText(KTextStyle(size: 22, weight: .bold, tracking: 4)).textSelection(.enabled)
            Spacer()
            Button {
                UIPasteboard.general.string = code
                copied = true
                Task { try? await Task.sleep(for: .seconds(1.5)); copied = false }
            } label: {
                smallLabel(copied ? String(localized: "Copied", bundle: .module) : String(localized: "Copy", bundle: .module),
                           symbol: copied ? "checkmark" : "doc.on.doc", prominent: false)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, KSpace.md).padding(.vertical, KSpace.sm + 2)
        .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: 10))
    }

    private func smallLabel(_ title: String, symbol: String, prominent: Bool) -> some View {
        Label(title, systemImage: symbol)
            .kText(KTextStyle(size: 13, weight: .semibold), color: prominent ? KColors.textOnBrand : KColors.textPrimary)
            .padding(.horizontal, KSpace.md).frame(maxWidth: prominent ? .infinity : nil, minHeight: 36)
            .background(prominent ? KColors.brand : KColors.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(prominent ? KColors.brand : KColors.border))
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }

    private func actionButton(_ title: String, symbol: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Label(title, systemImage: symbol).opacity(busy ? 0 : 1)
                if busy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
            }
            .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(KColors.brand, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private func shareText(_ link: InviteLink) -> String {
        String(localized: "Join \(data.kameti.name) on Kameti: \(link.link)\nOr open the app and enter the code \(link.code).", bundle: .module)
    }

    private func run(_ work: @escaping () async -> Failure?) {
        busy = true
        failure = nil
        Task {
            failure = await work()
            busy = false
        }
    }
}
