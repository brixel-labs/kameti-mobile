import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// A member's read-only view (boards A-Member-View, AD-Member-View; FR-60 to
/// FR-64): my due, my payout, this month's pot, the schedule and my payments.
/// It builds no write controls; the backend enforces the same rule.
struct MemberView: View {
    let data: KametiDetailData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                if let me = data.me {
                    content(for: me)
                } else {
                    ContentUnavailableView(
                        String(localized: "You're not a member of this kameti", bundle: .module), systemImage: "person.slash",
                        description: Text("Ask the owner to send you an invite.", bundle: .module)
                    )
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.bottom, KSpace.xl)
        }
    }

    @ViewBuilder
    private func content(for me: Member) -> some View {
        let balance = data.balances.first { $0.memberId == me.id }
        let mine = DetailLogic.newestFirst(data.payments.filter { $0.memberId == me.id })

        KCard {
            VStack(alignment: .leading, spacing: KSpace.md) {
                if let balance {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My monthly due", bundle: .module).kText(KTextToken.bodySm, color: KColors.textSecondary)
                            KMoneyText(balance.monthlyDue, style: .display)
                        }
                        Spacer()
                        KBalancePill(balance: balance.balance)
                    }
                }
                if let turn = DetailLogic.nextTurn(for: me, kameti: data.kameti, from: data.current?.monthIndex ?? 1, slots: data.slots, shares: data.shares) {
                    Divider()
                    let month = DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: turn.monthIndex))
                    Label(String(localized: "Your turn: \(month) · \(turn.payout.format())", bundle: .module), systemImage: "star.fill")
                        .kText(KTextToken.bodyStrong, color: KColors.onYourTurn)
                        .padding(KSpace.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KColors.yourTurn, in: RoundedRectangle(cornerRadius: KRadius.input))
                }
            }
        }

        if let current = data.current {
            KSectionHeader(String(localized: "This month", bundle: .module))
            KCard {
                VStack(alignment: .leading, spacing: KSpace.md) {
                    HStack {
                        Text(DetailLogic.monthTitle(current.monthStart)).kText(KTextToken.bodyStrong)
                        Spacer()
                        CollectionStatePill(state: current.state)
                    }
                    KPotProgress(
                        collected: current.received, target: current.target,
                        caption: String(localized: "\(current.paidCount) of \(current.memberCount) paid", bundle: .module)
                    )
                }
            }
        }

        KSectionHeader(String(localized: "Schedule", bundle: .module))
        ScheduleSection(data: data)

        KSectionHeader(String(localized: "My payments", bundle: .module))
        if mine.isEmpty {
            Text("You haven't made any payments yet.", bundle: .module)
                .kText(KTextToken.bodySm, color: KColors.textSecondary)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(mine.enumerated()), id: \.element.id) { index, payment in
                    PaymentRow(payment: payment, member: me, members: data.members, showsMember: false, showsDivider: index < mine.count - 1)
                }
            }
        }
    }
}
