import KametiCore
import KametiDomain

/// The pre-start checks of FR-12, shown on the review step. The server
/// re-checks on start (`kameti_not_ready`); these let the owner fix things first.
public struct PlanChecks: Equatable, Sendable {
    /// Slots (by payout month) with no shares.
    public var emptySlots: [Int] = []
    /// Slots whose shares don't add up to C, or break the Rs 1,000 / 4-sharer rules.
    public var badSlots: [Int] = []
    /// Members above the per-member slot limit.
    public var overLimit: [Member] = []
    /// Members with no share in any slot.
    public var unassigned: [Member] = []

    public var slotsFilled: Bool { emptySlots.isEmpty }
    public var slotsAddUp: Bool { badSlots.isEmpty }
    public var withinLimit: Bool { overLimit.isEmpty }
    public var passes: Bool { slotsFilled && slotsAddUp && withinLimit }

    /// Active shares of a slot, in the order they were added.
    public nonisolated static func activeShares(of slotId: String, in shares: [Share]) -> [Share] {
        shares.filter { $0.slotId == slotId && $0.effectiveToMonth == nil }
    }

    /// Whether one slot's shares are valid: they sum to `slotAmount`, each is
    /// at least Rs 1,000 and a multiple of Rs 1,000, at most 4 people.
    public nonisolated static func isValidSplit(_ amounts: [Money], slotAmount: Money) -> Bool {
        guard !amounts.isEmpty, amounts.count <= 4 else { return false }
        let total = amounts.reduce(Money.zero, +)
        return total == slotAmount && amounts.allSatisfy { $0.rupees >= 1_000 && $0.rupees % 1_000 == 0 }
    }

    public nonisolated static func evaluate(
        slotAmount: Money, maxSlotsPerMember: Int, members: [Member], slots: [Slot], shares: [Share]
    ) -> PlanChecks {
        var result = PlanChecks()
        var slotCount: [String: Int] = [:]
        for slot in slots.sorted(by: { $0.payoutMonthIndex < $1.payoutMonthIndex }) {
            let active = activeShares(of: slot.id, in: shares)
            if active.isEmpty {
                result.emptySlots.append(slot.payoutMonthIndex)
                continue
            }
            if !isValidSplit(active.map(\.monthlyAmount), slotAmount: slotAmount) {
                result.badSlots.append(slot.payoutMonthIndex)
            }
            for memberId in Set(active.map(\.memberId)) { slotCount[memberId, default: 0] += 1 }
        }
        result.overLimit = members.filter { slotCount[$0.id, default: 0] > maxSlotsPerMember }
        result.unassigned = members.filter { slotCount[$0.id, default: 0] == 0 }
        return result
    }

    /// What one slot still needs to reach `slotAmount` (negative when over).
    public nonisolated static func remaining(_ amounts: [Money], slotAmount: Money) -> Money {
        slotAmount - amounts.reduce(Money.zero, +)
    }

    /// Splits `slotAmount` evenly in Rs 1,000 steps between `count` people;
    /// the first person takes any remainder. `nil` when it can't be done.
    public nonisolated static func evenSplit(slotAmount: Money, count: Int) -> [Money]? {
        guard count >= 1, count <= 4, slotAmount.rupees % 1_000 == 0 else { return nil }
        let steps = slotAmount.rupees / 1_000
        guard steps >= count else { return nil }
        let base = steps / count, extra = steps % count
        return (0..<count).map { Money((base + ($0 < extra ? 1 : 0)) * 1_000) }
    }
}
