import Foundation
import KametiCore
import KametiDomain
import Testing
@testable import FeatureKametiDetail

private let kameti = Kameti(
    id: "k", ownerId: "o", name: "K", startMonth: DateOnly.make(year: 2026, month: 11), monthsN: 4,
    slotAmountC: Money(100_000), dueDay: 10, reminderDays: [], maxSlotsPerMember: 4, status: .active
)
private let members = [
    Member(id: "a", kametiId: "k", name: "A", joinStatus: .joined),
    Member(id: "b", kametiId: "k", name: "B", joinStatus: .joined),
    Member(id: "c", kametiId: "k", name: "C", joinStatus: .joined),
]
private let slots = [Slot(id: "s1", kametiId: "k", payoutMonthIndex: 1), Slot(id: "s2", kametiId: "k", payoutMonthIndex: 2)]
private func share(_ slot: String, _ member: String, _ amount: Int) -> Share {
    Share(id: slot + member, kametiId: "k", slotId: slot, memberId: member, monthlyAmount: Money(amount), effectiveFromMonth: 1)
}
private func balance(_ member: String, owes: Int) -> MemberBalanceRow {
    MemberBalanceRow(kametiId: "k", memberId: member, currentMonthIndex: 1, monthlyDue: Money(1), dueToDate: Money(1), totalPaid: .zero, balance: Money(owes), owes: Money(owes), credit: .zero)
}

@Suite("PayoutLogic")
struct PayoutLogicTests {
    private func recipients(shortfall: Int, balances: [MemberBalanceRow] = [], payouts: [Payout] = []) -> [PayoutRecipient] {
        PayoutLogic.recipients(
            kameti: kameti, month: 1, members: members, slots: slots, shares: [share("s1", "a", 60_000), share("s1", "b", 40_000), share("s2", "c", 100_000)],
            payouts: payouts, balances: balances, shortfall: Money(shortfall)
        )
    }

    @Test func recipientsAreTheSlotsSharersWithShareTimesN() {
        let result = recipients(shortfall: 0)
        #expect(result.map(\.id) == ["a", "b"])
        #expect(result.map(\.expected) == [Money(240_000), Money(160_000)])
        #expect(result.map(\.suggested) == [Money(240_000), Money(160_000)])
    }

    @Test func theShortfallIsSplitByShareAndAddsUpExactly() {
        let result = recipients(shortfall: 30_001)
        #expect(result.map(\.shortfallShare) == [Money(18_000), Money(12_001)])
        #expect(result.reduce(0) { $0 + $1.shortfallShare.rupees } == 30_001)
        #expect(result[0].suggested == Money(222_000))
    }

    @Test func earlierPartsReduceWhatIsOutstanding() {
        let part = Payout(id: "p", kametiId: "k", slotId: "s1", memberId: "a", amount: Money(100_000), paidOn: DateOnly.make(year: 2026, month: 11, day: 5), method: .cash)
        let voided = Payout(id: "v", kametiId: "k", slotId: "s1", memberId: "a", amount: Money(50_000), paidOn: DateOnly.make(year: 2026, month: 11, day: 5), method: .cash, voidedAt: Date(), voidReason: "x")
        let result = recipients(shortfall: 0, payouts: [part, voided])
        #expect(result[0].alreadyPaid == Money(100_000))
        #expect(result[0].outstanding == Money(140_000))
    }

    @Test func aSlotWithNoPayoutMonthHasNoRecipients() {
        let none = PayoutLogic.recipients(kameti: kameti, month: 3, members: members, slots: slots, shares: [], payouts: [], balances: [], shortfall: .zero)
        #expect(none.isEmpty)
    }

    @Test func deductingDuesMovesThemFromThePayoutToAPayment() {
        var draft = PayoutDraft(recipients: recipients(shortfall: 0, balances: [balance("a", owes: 100_000)]))
        #expect(!draft.needsNote)
        draft.setDeduction("a", on: true)
        #expect(draft.deduction("a") == Money(100_000))
        #expect(draft.amount("a") == Money(140_000))
        #expect(!draft.differs("a")) // payout + deduction still equals what is expected
        draft.setDeduction("a", on: false)
        #expect(draft.deduction("a") == nil && draft.amount("a") == Money(240_000))
    }

    @Test func aDeductionIsCappedAtThePayout() {
        var draft = PayoutDraft(recipients: recipients(shortfall: 0, balances: [balance("b", owes: 999_999)]))
        draft.setDeduction("b", on: true)
        #expect(draft.deduction("b") == Money(160_000))
        #expect(draft.amount("b") == .zero)
    }

    @Test func changingAnAmountNeedsANote() {
        var draft = PayoutDraft(recipients: recipients(shortfall: 0))
        #expect(!draft.needsNote)
        draft.set("a", to: Money(200_000))
        #expect(draft.differs("a") && draft.needsNote)
        #expect(draft.total == Money(360_000))
        draft.set("a", to: Money(-5))
        #expect(draft.amount("a") == .zero)
    }
}
