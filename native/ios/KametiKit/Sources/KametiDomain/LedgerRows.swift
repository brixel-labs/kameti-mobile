import Foundation
import KametiCore

/// Matches `public.month_payment_status`.
public enum MonthStatusCode: String, Codable, Hashable, Sendable {
    case paid, partial, unpaid, overdue, advance, upcoming
}

/// Matches `public.month_collection_state`.
public enum MonthCollectionState: String, Codable, Hashable, Sendable {
    case upcoming, collecting
    case fullyCollected = "fully_collected"
    case partiallyPaidOut = "partially_paid_out"
    case paidOut = "paid_out"
    case paidOutShort = "paid_out_short"
}

/// Row of the `member_balances` view. Balances are calculated by the
/// backend, never stored or recomputed on the device.
public struct MemberBalanceRow: Codable, Hashable, Sendable {
    public let kametiId: String
    public let memberId: String
    public let currentMonthIndex: Int
    public let monthlyDue: Money
    public let dueToDate: Money
    public let totalPaid: Money
    public let balance: Money
    public let owes: Money
    public let credit: Money

    public init(
        kametiId: String, memberId: String, currentMonthIndex: Int, monthlyDue: Money,
        dueToDate: Money, totalPaid: Money, balance: Money, owes: Money, credit: Money
    ) {
        self.kametiId = kametiId; self.memberId = memberId
        self.currentMonthIndex = currentMonthIndex; self.monthlyDue = monthlyDue
        self.dueToDate = dueToDate; self.totalPaid = totalPaid
        self.balance = balance; self.owes = owes; self.credit = credit
    }
}

/// Row of the `member_month_status` view.
public struct MemberMonthRow: Codable, Hashable, Sendable {
    public let kametiId: String
    public let memberId: String
    public let monthIndex: Int
    public let monthStart: Date
    public let isCurrent: Bool
    public let due: Money
    public let allocated: Money
    public let remaining: Money
    public let status: MonthStatusCode

    public init(
        kametiId: String, memberId: String, monthIndex: Int, monthStart: Date,
        isCurrent: Bool, due: Money, allocated: Money, remaining: Money,
        status: MonthStatusCode
    ) {
        self.kametiId = kametiId; self.memberId = memberId; self.monthIndex = monthIndex
        self.monthStart = monthStart; self.isCurrent = isCurrent; self.due = due
        self.allocated = allocated; self.remaining = remaining; self.status = status
    }
}

/// Row of the `month_collection` view: received (cash) vs covered (dues).
public struct MonthCollectionRow: Codable, Hashable, Sendable {
    public let kametiId: String
    public let monthIndex: Int
    public let monthStart: Date
    public let isCurrent: Bool
    public let target: Money
    public let received: Money
    public let covered: Money
    public let paidCount: Int
    public let memberCount: Int
    public let payoutShortfall: Money
    public let paidOut: Money
    public let recipients: Int
    public let recipientsPaid: Int
    public let paidOutShortBy: Money
    public let state: MonthCollectionState

    public init(
        kametiId: String, monthIndex: Int, monthStart: Date, isCurrent: Bool,
        target: Money, received: Money, covered: Money, paidCount: Int, memberCount: Int,
        payoutShortfall: Money, paidOut: Money, recipients: Int, recipientsPaid: Int,
        paidOutShortBy: Money, state: MonthCollectionState
    ) {
        self.kametiId = kametiId; self.monthIndex = monthIndex; self.monthStart = monthStart
        self.isCurrent = isCurrent; self.target = target; self.received = received
        self.covered = covered; self.paidCount = paidCount; self.memberCount = memberCount
        self.payoutShortfall = payoutShortfall; self.paidOut = paidOut
        self.recipients = recipients; self.recipientsPaid = recipientsPaid
        self.paidOutShortBy = paidOutShortBy; self.state = state
    }
}
