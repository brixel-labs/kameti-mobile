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

/// Tap-to-settle (board A v2 · Record many, option 3): the owner marks who paid
/// what for a month, then saves them together. Tapping a person marks what
/// they still owe; the amount can be edited; nothing is saved until the end.
public struct CollectSession: Equatable, Sendable {
    public struct Line: Equatable, Sendable, Identifiable {
        public let memberId: String
        /// What the member still owes this month.
        public let remaining: Money
        public var id: String { memberId }
    }

    public enum RowState: Equatable, Sendable {
        case unmarked
        /// Marked for at least what they owe.
        case settled(Money)
        /// Marked for less; this much would still be owed.
        case partial(Money, stillOwes: Money)
    }

    public let lines: [Line]
    public private(set) var marked: [String: Money] = [:]

    public init(lines: [Line]) { self.lines = lines }

    /// The members who still owe for the current month, in member order.
    public init(data: KametiDetailData) {
        let monthIndex = data.current?.monthIndex
        let owing = data.months.filter { $0.monthIndex == monthIndex && $0.remaining.isPositive }
        let order = Dictionary(uniqueKeysWithValues: data.members.enumerated().map { ($1.id, $0) })
        self.init(lines: owing.sorted { (order[$0.memberId] ?? 0) < (order[$1.memberId] ?? 0) }
            .map { Line(memberId: $0.memberId, remaining: $0.remaining) })
    }

    public var total: Money { marked.values.reduce(.zero, +) }
    public var count: Int { marked.count }
    public var allMarked: Bool { !lines.isEmpty && lines.allSatisfy { marked[$0.memberId] != nil } }

    public func state(of id: String) -> RowState {
        guard let amount = marked[id], let line = lines.first(where: { $0.memberId == id }) else { return .unmarked }
        return amount >= line.remaining ? .settled(amount) : .partial(amount, stillOwes: line.remaining - amount)
    }

    /// Tap: marks what they owe, or undoes a mark.
    public mutating func toggle(_ id: String) {
        if marked[id] != nil { marked[id] = nil } else if let line = lines.first(where: { $0.memberId == id }) { marked[id] = line.remaining }
    }

    /// Edit: a custom amount (zero or less clears the mark).
    public mutating func set(_ id: String, to amount: Money) {
        guard lines.contains(where: { $0.memberId == id }) else { return }
        marked[id] = amount.isPositive ? amount : nil
    }

    /// "Mark all paid": everyone who owes, for what they owe; a second tap clears.
    public mutating func markAll() {
        if allMarked { marked = [:] } else { for line in lines { marked[line.memberId] = line.remaining } }
    }

    /// The payments to save, one per marked member, in list order.
    public func items(keys: [String: String]) -> [BatchPaymentItem] {
        lines.compactMap { line in
            marked[line.memberId].map { BatchPaymentItem(memberId: line.memberId, amount: $0, idempotencyKey: keys[line.memberId] ?? line.memberId) }
        }
    }
}
