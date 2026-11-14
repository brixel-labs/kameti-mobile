import Foundation

/// The time of day a kameti's reminders go out, Pakistan time: a whole hour the owner picks
/// in the create wizard and in Edit kameti. The backend sends them on the hour (06:00 to 22:00).
public enum ReminderTime {
    public static let hours = 6...22
    public static let defaultHour = 10

    /// "10:00 AM", "12:00 PM", "6:00 PM". The hour is clamped into the allowed range.
    public static func label(_ hour: Int) -> String {
        let hour = min(max(hour, hours.lowerBound), hours.upperBound)
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        return "\(twelve):00 " + (hour < 12 ? "AM" : "PM")
    }
}
