import KametiCore
import KametiDomain

/// What recording an amount does for a member this month (shown under the
/// amount field before the owner confirms).
public enum PaymentOutcome: Equatable, Sendable {
    case none
    /// The member will be fully paid for the month.
    case fullyPaid
    /// Still owed for the month after this payment.
    case stillOwes(Money)
    /// More than the month needs; the extra covers later months.
    case credit(Money)
}

public enum PaymentLogic {
    /// The member's row for the current month (what they owe and have paid).
    public static func monthRow(for memberId: String, in data: KametiDetailData) -> MemberMonthRow? {
        guard let month = data.current?.monthIndex else { return nil }
        return data.months.first { $0.memberId == memberId && $0.monthIndex == month }
    }

    public static func outcome(amount: Money, row: MemberMonthRow?) -> PaymentOutcome {
        guard amount.isPositive, let row else { return .none }
        let remaining = row.remaining.rupees
        if amount.rupees == remaining { return .fullyPaid }
        if amount.rupees < remaining { return .stillOwes(Money(remaining - amount.rupees)) }
        return .credit(Money(amount.rupees - remaining))
    }

    /// Members the owner can record a payment for: those with a due this month.
    public static func payers(in data: KametiDetailData) -> [Member] {
        let ids = Set(data.months.filter { $0.monthIndex == data.current?.monthIndex }.map(\.memberId))
        return data.members.filter { ids.contains($0.id) }
    }
}
