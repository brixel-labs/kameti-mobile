import Testing
@testable import KametiCore

@Suite("ReminderTime")
struct ReminderTimeTests {
    @Test("the hour reads as a 12-hour clock", arguments: [
        (6, "6:00 AM"), (10, "10:00 AM"), (11, "11:00 AM"), (12, "12:00 PM"), (13, "1:00 PM"), (18, "6:00 PM"), (22, "10:00 PM"),
    ])
    func label(hour: Int, expected: String) {
        #expect(ReminderTime.label(hour) == expected)
    }

    @Test func hoursStayBetweenSixAndTen() {
        #expect(ReminderTime.hours == 6...22)
        #expect(ReminderTime.hours.contains(ReminderTime.defaultHour))
        #expect(ReminderTime.label(2) == "6:00 AM")
        #expect(ReminderTime.label(30) == "10:00 PM")
    }
}
