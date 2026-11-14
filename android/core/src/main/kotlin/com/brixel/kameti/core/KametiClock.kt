package com.brixel.kameti.core

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset

/**
 * The single source of "now" for kameti logic.
 *
 * All due dates and month boundaries are in Pakistan time (UTC+5, no
 * daylight saving) wherever the device is. Use this instead of
 * `Instant.now()` so tests can control time.
 */
class KametiClock(private val nowUtc: () -> Instant = Instant::now) {
    /** The real current moment. */
    fun now(): Instant = nowUtc()

    /** Today's date in Pakistan time. */
    fun today(): LocalDate = nowUtc().atOffset(PAKISTAN).toLocalDate()

    /** First day of the current month in Pakistan time. */
    fun currentMonth(): LocalDate = today().withDayOfMonth(1)

    /**
     * 1-based month index of the current month in a kameti that starts in
     * [startMonth]. Returns 0 before it starts and `months + 1` after it ends.
     */
    fun monthIndex(startMonth: LocalDate, months: Int): Int {
        val current = currentMonth()
        val diff = (current.year - startMonth.year) * 12 + (current.monthValue - startMonth.monthValue)
        return when {
            diff < 0 -> 0
            diff >= months -> months + 1
            else -> diff + 1
        }
    }

    companion object {
        val PAKISTAN: ZoneOffset = ZoneOffset.ofHours(5)
    }
}
