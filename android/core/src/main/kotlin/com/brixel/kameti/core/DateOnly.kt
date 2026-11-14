package com.brixel.kameti.core

import java.time.DateTimeException
import java.time.LocalDate

/**
 * Postgres `date` columns (`YYYY-MM-DD`) as [LocalDate]: "a calendar day
 * without a time". A month is the first day of that month.
 */
object DateOnly {
    /** The given calendar day (month is 1..12). */
    fun make(year: Int, month: Int, day: Int = 1): LocalDate = LocalDate.of(year, month, day)

    /** Parses `YYYY-MM-DD`; `null` for anything else. */
    fun parse(text: String): LocalDate? {
        val parts = text.split("-")
        if (parts.size != 3) return null
        val year = parts[0].toIntOrNull() ?: return null
        val month = parts[1].toIntOrNull() ?: return null
        val day = parts[2].toIntOrNull() ?: return null
        return try {
            LocalDate.of(year, month, day)
        } catch (_: DateTimeException) {
            null
        }
    }

    /** `YYYY-MM-DD`, as the backend expects dates in RPC arguments. */
    fun string(date: LocalDate): String =
        "%04d-%02d-%02d".format(date.year, date.monthValue, date.dayOfMonth)
}
