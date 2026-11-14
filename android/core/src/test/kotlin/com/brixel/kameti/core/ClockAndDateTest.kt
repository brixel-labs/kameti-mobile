package com.brixel.kameti.core

import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class ClockAndDateTest {
    private fun clock(iso: String): KametiClock {
        val instant = Instant.parse(iso)
        return KametiClock { instant }
    }

    @Test
    fun pakistanMonthStartsBeforeUtc() {
        // 20:30 UTC on 31 Oct is already 1 Nov 01:30 in Pakistan.
        assertEquals(DateOnly.make(2026, 11), clock("2026-10-31T20:30:00Z").currentMonth())
        assertEquals(DateOnly.make(2026, 10), clock("2026-10-31T18:30:00Z").currentMonth())
    }

    @Test
    fun monthIndexInsideBeforeAndAfter() {
        val start = DateOnly.make(2026, 10)
        assertEquals(2, clock("2026-11-10T09:00:00Z").monthIndex(start, 20))
        assertEquals(0, clock("2026-09-15T09:00:00Z").monthIndex(start, 20))
        assertEquals(21, clock("2028-06-01T09:00:00Z").monthIndex(start, 20))
        assertEquals(1, clock("2026-10-02T09:00:00Z").monthIndex(start, 20))
    }

    @Test
    fun dateOnlyRoundTrips() {
        val day = DateOnly.make(2026, 3, 5)
        assertEquals("2026-03-05", DateOnly.string(day))
        assertEquals(day, DateOnly.parse("2026-03-05"))
    }

    @Test
    fun dateOnlyRejectsOtherText() {
        assertNull(DateOnly.parse("2026-13-01"))
        assertNull(DateOnly.parse("2026-03"))
        assertNull(DateOnly.parse("2026-11-09T10:00:00Z"))
    }
}
