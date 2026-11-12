import Foundation
import KametiCore
import KametiDomain
import Testing
@testable import FeatureCreateKameti

private func member(_ id: String) -> Member { Member(id: id, kametiId: "k", name: id, joinStatus: .joined) }
private func slot(_ month: Int) -> Slot { Slot(id: "s\(month)", kametiId: "k", payoutMonthIndex: month) }
private func share(_ slot: Int, _ member: String, _ amount: Int) -> Share {
    Share(id: "\(slot)\(member)", kametiId: "k", slotId: "s\(slot)", memberId: member, monthlyAmount: Money(amount), effectiveFromMonth: 1)
}

@Suite("PlanChecks")
struct PlanChecksTests {
    @Test func splitMustSumToTheSlotAndUseThousands() {
        let c = Money(100_000)
        #expect(PlanChecks.isValidSplit([Money(100_000)], slotAmount: c))
        #expect(PlanChecks.isValidSplit([Money(60_000), Money(40_000)], slotAmount: c))
        #expect(!PlanChecks.isValidSplit([Money(60_000), Money(30_000)], slotAmount: c))
        #expect(!PlanChecks.isValidSplit([Money(99_500), Money(500)], slotAmount: c))
        #expect(!PlanChecks.isValidSplit([], slotAmount: c))
        #expect(!PlanChecks.isValidSplit(Array(repeating: Money(20_000), count: 5), slotAmount: c))
    }

    @Test func emptyBadAndOverLimitSlotsAreFound() {
        let members = [member("a"), member("b"), member("c")]
        let slots = [slot(1), slot(2), slot(3)]
        let shares = [share(1, "a", 100_000), share(2, "a", 60_000)] // slot 2 short, slot 3 empty
        let result = PlanChecks.evaluate(slotAmount: Money(100_000), maxSlotsPerMember: 1, members: members, slots: slots, shares: shares)
        #expect(result.emptySlots == [3])
        #expect(result.badSlots == [2])
        #expect(result.overLimit.map(\.id) == ["a"])
        #expect(result.unassigned.map(\.id) == ["b", "c"])
        #expect(!result.passes)
    }

    @Test func aCompleteValidPlanPasses() {
        let result = PlanChecks.evaluate(
            slotAmount: Money(100_000), maxSlotsPerMember: 4, members: [member("a"), member("b")],
            slots: [slot(1), slot(2)], shares: [share(1, "a", 100_000), share(2, "b", 100_000)]
        )
        #expect(result.passes)
        #expect(result.unassigned.isEmpty)
    }

    @Test func removedSharesDoNotCount() {
        let ended = Share(id: "x", kametiId: "k", slotId: "s1", memberId: "a", monthlyAmount: Money(100_000), effectiveFromMonth: 1, effectiveToMonth: 2)
        let result = PlanChecks.evaluate(slotAmount: Money(100_000), maxSlotsPerMember: 4, members: [member("a")], slots: [slot(1)], shares: [ended])
        #expect(result.emptySlots == [1])
    }

    @Test func evenSplitUsesThousandsAndGivesTheRemainderToTheFirst() {
        #expect(PlanChecks.evenSplit(slotAmount: Money(100_000), count: 2) == [Money(50_000), Money(50_000)])
        #expect(PlanChecks.evenSplit(slotAmount: Money(100_000), count: 3) == [Money(34_000), Money(33_000), Money(33_000)])
        #expect(PlanChecks.evenSplit(slotAmount: Money(2_000), count: 3) == nil)
        #expect(PlanChecks.evenSplit(slotAmount: Money(100_000), count: 5) == nil)
        #expect(PlanChecks.evenSplit(slotAmount: Money(100_500), count: 2) == nil)
    }

    @Test func remainingCanGoNegative() {
        #expect(PlanChecks.remaining([Money(60_000)], slotAmount: Money(100_000)) == Money(40_000))
        #expect(PlanChecks.remaining([Money(70_000), Money(50_000)], slotAmount: Money(100_000)) == Money(-20_000))
    }
}
