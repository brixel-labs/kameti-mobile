import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Approve a join (board AF-Approve-Join): someone accepted an invite with a
/// different email than the one it was sent to, so the owner checks it's
/// really them. Used from the member sheet and from Inbox.
public struct ApproveJoinSheet: View {
    let memberName: String
    let invitedEmail: String?
    let acceptedEmail: String?
    let approve: () async -> Failure?
    let reject: () async -> Failure?
    let onDone: () -> Void

    @State private var busy: Action?
    @State private var failure: Failure?

    private enum Action { case approve, reject }

    public init(
        memberName: String, invitedEmail: String?, acceptedEmail: String?,
        approve: @escaping () async -> Failure?, reject: @escaping () async -> Failure?, onDone: @escaping () -> Void
    ) {
        self.memberName = memberName
        self.invitedEmail = invitedEmail
        self.acceptedEmail = acceptedEmail
        self.approve = approve
        self.reject = reject
        self.onDone = onDone
    }

    private var firstName: String { memberName.split(separator: " ").first.map(String.init) ?? memberName }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                HStack(spacing: KSpace.md) {
                    KAvatar(name: memberName, colorIndex: 1, size: .medium)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(memberName) wants to join", bundle: .module).kText(KTextToken.title)
                        Text("Accepted your invite", bundle: .module).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                    }
                }
                Label(
                    String(localized: "They signed in with a different email than the one you invited. Make sure it's really \(firstName) before approving.", bundle: .module),
                    systemImage: "exclamationmark.circle"
                )
                .kText(KTextToken.bodySm, color: KColors.warning)
                .padding(KSpace.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: 12))

                VStack(spacing: KSpace.sm) {
                    emailBox(String(localized: "You invited", bundle: .module), invitedEmail)
                    emailBox(String(localized: "Signed in as", bundle: .module), acceptedEmail.map(InviteLogic.masked))
                }
                Text("Until you approve, they can't see anything in this kameti. Apple's \"Hide My Email\" often causes this; a quick WhatsApp check is enough.", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)

                if let failure {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                        .kText(KTextToken.bodySm, color: KColors.negative)
                }
                SplitRow(spacing: KSpace.md) {
                    Button { run(.reject) } label: {
                        busyLabel(String(localized: "Reject", bundle: .module), action: .reject, color: KColors.negative)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(KColors.negative.opacity(0.4)))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    Button { run(.approve) } label: {
                        busyLabel(String(localized: "Approve \(firstName)", bundle: .module), action: .approve, color: KColors.textOnBrand)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(KColors.brand)
                    .controlSize(.large)
                }
                .disabled(busy != nil)
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xxs)
            .padding(.bottom, KSpace.xl)
        }
    }

    private func emailBox(_ title: String, _ email: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).kText(KTextStyle(size: 12, weight: .semibold), color: KColors.textSecondary)
            Text(email ?? String(localized: "Not known", bundle: .module)).kText(KTextToken.bodyStrong)
                .textSelection(.enabled)
        }
        .padding(KSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: 12))
    }

    private func busyLabel(_ title: String, action: Action, color: Color) -> some View {
        ZStack {
            Text(title).opacity(busy == action ? 0 : 1)
            if busy == action { ProgressView().controlSize(.small).tint(color) }
        }
        .kText(KTextToken.bodyStrong, color: color)
    }

    private func run(_ action: Action) {
        busy = action
        failure = nil
        Task {
            let result = action == .approve ? await approve() : await reject()
            busy = nil
            if let result { failure = result } else { onDone() }
        }
    }
}
