import KametiCore
import KametiDomain

/// One person receiving (part of) a month's pot (FR-51 to FR-53).
public struct PayoutRecipient: Equatable, Sendable, Identifiable {
    public let slotId: String
    public let member: Member
    public let colorIndex: Int
    /// Their share of the slot per month.
    public let monthlyShare: Money
    /// Share × N.
    public let expected: Money
    /// Payouts already recorded for this slot (a payout can be made in parts).
    public let alreadyPaid: Money
    /// Their part of the month's shortfall, split by share.
    public let shortfallShare: Money
    /// What they owe in dues right now.
    public let owes: Money

    public var id: String { member.id }

    /// What is still expected after earlier parts.
    public var outstanding: Money {
        let rest = expected - alreadyPaid
        return rest.isNegative ? .zero : rest
    }

    /// Pre-filled amount: what is still expected, less their part of the
    /// shortfall, never below zero.
    public var suggested: Money {
        let rest = outstanding - shortfallShare
        return rest.isNegative ? .zero : rest
    }
}

public enum PayoutLogic {
    /// The recipients of month `month`'s slot, in member order. The shortfall
    /// is split by share: each takes `shortfall × share ÷ C` rounded down and
    /// the last takes the remainder, so the parts add up exactly.
    public static func recipients(
        kameti: Kameti, month: Int, members: [Member], slots: [Slot], shares: [Share],
        payouts: [Payout], balances: [MemberBalanceRow], shortfall: Money
    ) -> [PayoutRecipient] {
        guard let slot = slots.first(where: { $0.payoutMonthIndex == month }) else { return [] }
        var shareByMember: [String: Int] = [:]
        for share in shares where share.slotId == slot.id && DetailLogic.isActive(share, in: month) {
            shareByMember[share.memberId, default: 0] += share.monthlyAmount.rupees
        }
        let ordered = members.enumerated().filter { shareByMember[$0.element.id] != nil }
        let c = kameti.slotAmountC.rupees
        let short = shortfall.isPositive ? shortfall.rupees : 0
        var assigned = 0
        return ordered.enumerated().map { position, entry in
            let (index, member) = entry
            let share = shareByMember[member.id] ?? 0
            let isLast = position == ordered.count - 1
            let part = isLast ? short - assigned : (c == 0 ? 0 : short * share / c)
            assigned += part
            let paid = payouts.filter { $0.voidedAt == nil && $0.slotId == slot.id && $0.memberId == member.id }
                .reduce(Money.zero) { $0 + $1.amount }
            return PayoutRecipient(
                slotId: slot.id, member: member, colorIndex: index, monthlyShare: Money(share), expected: Money(share * kameti.monthsN),
                alreadyPaid: paid, shortfallShare: Money(part),
                owes: balances.first { $0.memberId == member.id }?.owes ?? .zero
            )
        }
    }
}

/// What the owner has entered on the payout screen.
public struct PayoutDraft: Equatable, Sendable {
    public let recipients: [PayoutRecipient]
    public private(set) var amounts: [String: Money]
    /// Dues taken from a payout (recorded as a payment, with a reduced payout).
    public private(set) var deductions: [String: Money] = [:]

    public init(recipients: [PayoutRecipient]) {
        self.recipients = recipients
        amounts = Dictionary(uniqueKeysWithValues: recipients.map { ($0.id, $0.suggested) })
    }

    public func amount(_ id: String) -> Money { amounts[id] ?? .zero }
    public func deduction(_ id: String) -> Money? { deductions[id] }

    public var total: Money { amounts.values.reduce(.zero, +) }
    public var hasAnything: Bool { total.isPositive || !deductions.isEmpty }

    public mutating func set(_ id: String, to amount: Money) {
        amounts[id] = amount.isNegative ? .zero : amount
    }

    /// "Ali owes Rs 1,00,000. Take it from his payout?": moves what they owe
    /// (at most the payout) from the payout to a recorded payment.
    public mutating func setDeduction(_ id: String, on: Bool) {
        guard let recipient = recipients.first(where: { $0.id == id }) else { return }
        let amount = self.amount(id)
        if on {
            let take = Money(min(recipient.owes.rupees, amount.rupees))
            guard take.isPositive else { return }
            deductions[id] = take
            amounts[id] = amount - take
        } else if let take = deductions.removeValue(forKey: id) {
            amounts[id] = amount + take
        }
    }

    /// A payout (plus any deduction) that differs from what is still expected
    /// needs a note saying why (E22).
    public func differs(_ id: String) -> Bool {
        guard let recipient = recipients.first(where: { $0.id == id }) else { return false }
        return amount(id) + (deductions[id] ?? .zero) != recipient.outstanding
    }

    public var needsNote: Bool { recipients.contains { differs($0.id) } }
}
