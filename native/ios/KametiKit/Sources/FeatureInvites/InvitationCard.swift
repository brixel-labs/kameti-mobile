import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// An invitation on Home (board AI-1b): who invited me to which kameti,
/// with Decline and Review and join.
public struct InvitationCard: View {
    let invitation: MyInvitation
    let now: Date
    let onDecline: () -> Void
    let onReview: () -> Void

    public init(invitation: MyInvitation, now: Date, onDecline: @escaping () -> Void, onReview: @escaping () -> Void) {
        self.invitation = invitation
        self.now = now
        self.onDecline = onDecline
        self.onReview = onReview
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: KSpace.md) {
            HStack(spacing: KSpace.md) {
                Text(InviteLogic.initials(invitation.ownerName))
                    .kText(KTextStyle(size: 15, weight: .bold), color: KColors.onBrandSubtle)
                    .frame(width: 44, height: 44)
                    .background(KColors.brandSubtle, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(invitation.kametiName).kText(KTextToken.title)
                    Text("\(invitation.ownerName) invited you · \(InviteLogic.expiryText(invitation.expiresAt, now: now))", bundle: .module)
                        .kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                }
                Spacer(minLength: 0)
            }
            SplitRow(spacing: KSpace.md) {
                Button(action: onDecline) {
                    Text("Decline", bundle: .module).kText(KTextToken.bodyStrong)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(Capsule().strokeBorder(KColors.border))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                Button(action: onReview) {
                    Text("Review and join", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(KColors.brand, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(KSpace.lg)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).strokeBorder(KColors.brand, lineWidth: 2))
    }
}
