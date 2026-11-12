import Foundation
import Testing
@testable import KametiCore

@Suite("KametiClock and DateOnly")
struct ClockAndDateTests {
    private func clock(_ iso: String) -> KametiClock {
        let date = try! Date.ISO8601FormatStyle().parse(iso)
        return KametiClock(nowUTC: { date })
    }

    @Test func pakistanMonthStartsBeforeUTC() {
        // 20:30 UTC on 31 Oct is already 1 Nov 01:30 in Pakistan.
        #expect(clock("2026-10-31T20:30:00Z").currentMonth() == DateOnly.make(year: 2026, month: 11))
        #expect(clock("2026-10-31T18:30:00Z").currentMonth() == DateOnly.make(year: 2026, month: 10))
    }

    @Test func monthIndexInsideBeforeAndAfter() {
        let start = DateOnly.make(year: 2026, month: 10)
        #expect(clock("2026-11-10T09:00:00Z").monthIndex(startMonth: start, months: 20) == 2)
        #expect(clock("2026-09-15T09:00:00Z").monthIndex(startMonth: start, months: 20) == 0)
        #expect(clock("2028-06-01T09:00:00Z").monthIndex(startMonth: start, months: 20) == 21)
        #expect(clock("2026-10-02T09:00:00Z").monthIndex(startMonth: start, months: 20) == 1)
    }

    @Test func dateOnlyRoundTrips() {
        let day = DateOnly.make(year: 2026, month: 3, day: 5)
        #expect(DateOnly.string(from: day) == "2026-03-05")
        #expect(DateOnly.parse("2026-03-05") == day)
    }

    @Test func dateOnlyRejectsOtherText() {
        #expect(DateOnly.parse("2026-13-01") == nil)
        #expect(DateOnly.parse("2026-03") == nil)
        #expect(DateOnly.parse("2026-11-09T10:00:00Z") == nil)
    }
}
