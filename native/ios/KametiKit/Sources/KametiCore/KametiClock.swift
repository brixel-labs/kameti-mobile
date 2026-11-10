import Foundation

/// The single source of "now" for kameti logic.
///
/// All due dates and month boundaries are in Pakistan time (UTC+5, no
/// daylight saving) wherever the device is. Use this instead of `Date()` so
/// tests can control time.
public struct KametiClock: Sendable {
    public static let pakistanOffset: TimeInterval = 5 * 60 * 60

    private let nowUTC: @Sendable () -> Date

    public init(nowUTC: @escaping @Sendable () -> Date = { Date() }) {
        self.nowUTC = nowUTC
    }

    /// The real current moment.
    public func now() -> Date { nowUTC() }

    /// First day of the current month in Pakistan time, as a UTC-midnight date.
    public func currentMonth() -> Date {
        let shifted = nowUTC().addingTimeInterval(Self.pakistanOffset)
        let c = DateOnly.calendar.dateComponents([.year, .month], from: shifted)
        return DateOnly.make(year: c.year!, month: c.month!)
    }

    /// 1-based month index of the current month in a kameti that starts in
    /// `startMonth`. Returns 0 before it starts and `months + 1` after it ends.
    public func monthIndex(startMonth: Date, months: Int) -> Int {
        let current = DateOnly.calendar.dateComponents([.year, .month], from: currentMonth())
        let start = DateOnly.calendar.dateComponents([.year, .month], from: startMonth)
        let diff = (current.year! - start.year!) * 12 + (current.month! - start.month!)
        if diff < 0 { return 0 }
        if diff >= months { return months + 1 }
        return diff + 1
    }
}
