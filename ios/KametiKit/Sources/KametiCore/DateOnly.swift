import Foundation

/// Postgres `date` columns (`YYYY-MM-DD`) as UTC-midnight `Date`s, the same
/// convention the rest of the app uses for "a calendar day without a time".
public enum DateOnly {
    public static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    /// A UTC-midnight date for the given calendar day (month is 1...12).
    public static func make(year: Int, month: Int, day: Int = 1) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// Parses `YYYY-MM-DD`; `nil` for anything else.
    public static func parse(_ text: String) -> Date? {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              (1...12).contains(month), (1...31).contains(day)
        else { return nil }
        return make(year: year, month: month, day: day)
    }

    /// `YYYY-MM-DD`, as the backend expects dates in RPC arguments.
    public static func string(from date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}
