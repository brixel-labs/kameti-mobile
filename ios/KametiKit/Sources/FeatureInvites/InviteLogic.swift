import Foundation
import KametiCore
import KametiDomain

/// Small rules shared by the invite screens, kept apart from the views so
/// they can be tested.
public enum InviteLogic {
    /// Why this account can't join, said up front (E39), or `nil`.
    static func blockedReason(_ preview: InvitePreview) -> String? {
        if preview.isOwner == true {
            return String(localized: "You run this kameti, so you can't join it as a member.", bundle: .module)
        }
        if preview.alreadyMember == true {
            let name = preview.alreadyMemberName ?? ""
            return String(localized: "You're already a member of this kameti as \(name). If this invite is for you, ask \(preview.ownerName) to remove your app access from that record first.", bundle: .module)
        }
        return nil
    }

    /// Whole days left before `expiresAt` (0 on the last day, never negative).
    public static func daysLeft(until expiresAt: Date, now: Date) -> Int {
        max(Int((expiresAt.timeIntervalSince(now) / 86_400).rounded(.down)), 0)
    }

    /// "Expires in 12 days", "Expires tomorrow", "Expires today" or "Expired".
    public static func expiryText(_ expiresAt: Date, now: Date) -> String {
        guard expiresAt > now else { return String(localized: "Expired", bundle: .module) }
        switch daysLeft(until: expiresAt, now: now) {
        case 0: return String(localized: "Expires today", bundle: .module)
        case 1: return String(localized: "Expires tomorrow", bundle: .module)
        case let days: return String(localized: "Expires in \(days) days", bundle: .module)
        }
    }

    /// What the invitee pays each month: the sum of their shares.
    public static func monthlyTotal(_ shares: [InviteShare]) -> Money {
        shares.reduce(Money.zero) { $0 + $1.monthlyAmount }
    }

    /// "January 2027 · Month 3", or "Jan 2027 and Mar 2027" for more than one
    /// turn. Without a start month: "Month 3" or "Months 2 and 4".
    public static func turnsText(_ shares: [InviteShare], startMonth: Date? = nil) -> String? {
        let months = Array(Set(shares.map(\.payoutMonthIndex))).sorted()
        guard let last = months.last else { return nil }
        if let startMonth {
            if months.count == 1 {
                return String(localized: "\(monthTitle(monthStart(startMonth, index: last))) · Month \(last)", bundle: .module)
            }
            let names = months.map { shortMonth(monthStart(startMonth, index: $0)) }
            return String(localized: "\(names.dropLast().joined(separator: ", ")) and \(names[names.count - 1])", bundle: .module)
        }
        if months.count == 1 { return String(localized: "Month \(last)", bundle: .module) }
        let list = months.dropLast().map(String.init).joined(separator: ", ")
        return String(localized: "Months \(list) and \(last)", bundle: .module)
    }

    /// What the invitee receives in all: each share × N months.
    public static func payout(_ shares: [InviteShare], monthsN: Int) -> Money {
        shares.reduce(Money.zero) { $0 + Money($1.monthlyAmount.rupees * monthsN) }
    }

    /// "Nov 2026 → Feb 2027": the first and last month.
    public static func runsText(startMonth: Date, monthsN: Int) -> String {
        "\(shortMonth(startMonth)) → \(shortMonth(monthStart(startMonth, index: monthsN)))"
    }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    /// The first day of month `index` (1-based), as a date-only UTC value.
    static func monthStart(_ start: Date, index: Int) -> Date {
        utc.date(byAdding: .month, value: index - 1, to: start) ?? start
    }

    /// "January 2027".
    static func monthTitle(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(timeZone: utc.timeZone).month(.wide).year())
    }

    /// "Jan 2027".
    static func shortMonth(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(timeZone: utc.timeZone).month(.abbreviated).year())
    }

    /// Initials for an avatar: first letters of the first two words.
    public static func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    /// Hides most of an email: `x7••••••••@privaterelay.appleid.com`.
    public static func masked(_ email: String) -> String {
        let parts = email.split(separator: "@", maxSplits: 1)
        guard parts.count == 2 else { return email }
        let name = parts[0]
        let visible = name.prefix(min(2, name.count))
        return visible + String(repeating: "•", count: max(name.count - visible.count, 3)) + "@" + parts[1]
    }
}
