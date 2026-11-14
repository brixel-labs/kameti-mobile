package com.brixel.kameti.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Twin of ReminderTimeTests.swift. */
class ReminderTimeTest {
    @Test
    fun theHourReadsAsATwelveHourClock() {
        val expected = mapOf(
            6 to "6:00 AM", 10 to "10:00 AM", 11 to "11:00 AM", 12 to "12:00 PM", 13 to "1:00 PM", 18 to "6:00 PM", 22 to "10:00 PM",
        )
        for ((hour, label) in expected) assertEquals(label, ReminderTime.label(hour), "hour $hour")
    }

    @Test
    fun hoursStayBetweenSixAndTen() {
        assertEquals(6..22, ReminderTime.HOURS)
        assertTrue(ReminderTime.DEFAULT_HOUR in ReminderTime.HOURS)
        assertEquals("6:00 AM", ReminderTime.label(2))
        assertEquals("10:00 PM", ReminderTime.label(30))
    }
}
