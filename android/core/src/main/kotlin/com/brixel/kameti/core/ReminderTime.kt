package com.brixel.kameti.core

/**
 * The time of day a kameti's reminders go out, Pakistan time: a whole hour the owner picks
 * in the create wizard and in Edit kameti. The backend sends them on the hour (06:00 to 22:00).
 */
object ReminderTime {
    val HOURS = 6..22
    const val DEFAULT_HOUR = 10

    /** "10:00 AM", "12:00 PM", "6:00 PM". The hour is clamped into the allowed range. */
    fun label(hour: Int): String {
        val clamped = hour.coerceIn(HOURS)
        val twelve = if (clamped % 12 == 0) 12 else clamped % 12
        return "$twelve:00 " + if (clamped < 12) "AM" else "PM"
    }
}
