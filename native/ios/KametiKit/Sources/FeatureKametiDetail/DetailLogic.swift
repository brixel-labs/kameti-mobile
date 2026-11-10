import Foundation
import KametiCore
import KametiDomain

/// Pure helpers that join the kameti rows (members, slots, shares) for the
/// detail screens. No balance maths here: balances, statuses and totals come
/// from the backend views.
public enum DetailLogic {
    /// One person paid out in a month: their share × N.
    public struct Recipient: Equatable, Sendable, Identifiable {
        public let member: Member
        public let share: Share
        public let payout: Money
        public var id: String { share.id }
    }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// First day (UTC) of the 1-based `monthIndex` of `kameti`.
    public static func monthStart(of kameti: Kameti, monthIndex: Int) -> Date {
        utc.date(byAdding: .month, value: monthIndex - 1, to: kameti.startMonth) ?? kameti.startMonth
    }

    /// "October 2026", from a date-only (UTC) value.
    public static func monthTitle(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(timeZone: utc.timeZone).month(.wide).year())
    }

    /// The share counts in `monthIndex` (it started and hasn't ended).
    public static func isActive(_ share: Share, in monthIndex: Int) -> Bool {
        share.effectiveFromMonth <= monthIndex
            && (share.effectiveToMonth.map { $0 >= monthIndex } ?? true)
    }

    /// Who receives the pot in `monthIndex`, from the slot whose payout month it is.
    public static func recipients(
        kameti: Kameti, monthIndex: Int, slots: [Slot], shares: [Share], members: [Member]
    ) -> [Recipient] {
        let slotIds = Set(slots.filter { $0.payoutMonthIndex == monthIndex }.map(\.id))
        let byId = Dictionary(members.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return shares.compactMap { share in
            guard slotIds.contains(share.slotId), isActive(share, in: monthIndex),
                  let member = byId[share.memberId] else { return nil }
            return Recipient(member: member, share: share, payout: share.monthlyAmount * kameti.monthsN)
        }
    }

    /// The signed-in user's member row, if they are a member.
    public static func myMember(in members: [Member], userId: String?) -> Member? {
        guard let userId else { return nil }
        return members.first { $0.profileId == userId }
    }

    /// The row for the current month, if the kameti is running.
    public static func currentCollection(_ rows: [MonthCollectionRow]) -> MonthCollectionRow? {
        rows.first(where: \.isCurrent)
    }

    /// Members who still owe for `monthIndex` (partial, unpaid or overdue).
    public static func owing(_ months: [MemberMonthRow], monthIndex: Int) -> [MemberMonthRow] {
        months.filter { $0.monthIndex == monthIndex && [.partial, .unpaid, .overdue].contains($0.status) }
    }

    public struct StatusCounts: Equatable, Sendable {
        public var paid = 0, partial = 0, unpaid = 0
    }

    /// Paid (incl. advance), partial and unpaid (incl. overdue) counts for one month.
    public static func statusCounts(_ months: [MemberMonthRow], monthIndex: Int) -> StatusCounts {
        var counts = StatusCounts()
        for row in months where row.monthIndex == monthIndex {
            switch row.status {
            case .paid, .advance: counts.paid += 1
            case .partial: counts.partial += 1
            case .unpaid, .overdue: counts.unpaid += 1
            case .upcoming: break
            }
        }
        return counts
    }

    /// My next payout at or after `monthIndex`, with the amount.
    public static func nextTurn(
        for member: Member, kameti: Kameti, from monthIndex: Int, slots: [Slot], shares: [Share]
    ) -> (monthIndex: Int, payout: Money)? {
        let mine = slots.sorted { $0.payoutMonthIndex < $1.payoutMonthIndex }.compactMap { slot -> (Int, Money)? in
            guard slot.payoutMonthIndex >= monthIndex,
                  let share = shares.first(where: {
                      $0.slotId == slot.id && $0.memberId == member.id && isActive($0, in: slot.payoutMonthIndex)
                  }) else { return nil }
            return (slot.payoutMonthIndex, share.monthlyAmount * kameti.monthsN)
        }
        return mine.first.map { (monthIndex: $0.0, payout: $0.1) }
    }

    /// Newest first: by received date, then by when it was recorded.
    public static func newestFirst(_ payments: [Payment]) -> [Payment] {
        payments.sorted {
            $0.receivedOn != $1.receivedOn ? $0.receivedOn > $1.receivedOn : $0.createdAt > $1.createdAt
        }
    }

    /// "Bank · ref 88213 · paid by Hassan".
    public static func paymentSubtitle(_ payment: Payment, methodLabel: String, paidBy: (String) -> String) -> String {
        var parts = [methodLabel]
        if let reference = payment.reference, !reference.isEmpty { parts.append(reference) }
        if let name = payment.paidByName, !name.isEmpty { parts.append(paidBy(name)) }
        return parts.joined(separator: " · ")
    }
}
