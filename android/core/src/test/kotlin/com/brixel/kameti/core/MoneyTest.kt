package com.brixel.kameti.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.serialization.json.Json

class MoneyTest {
    @Test
    fun formatUsesLakhCroreGrouping() {
        val cases = listOf(
            0L to "Rs 0", 999L to "Rs 999", 1000L to "Rs 1,000", 50000L to "Rs 50,000",
            125_000L to "Rs 1,25,000", 2_500_000L to "Rs 25,00,000", 4_970_000L to "Rs 49,70,000",
            5_000_000L to "Rs 50,00,000", 12_345_678L to "Rs 1,23,45,678",
        )
        for ((rupees, expected) in cases) assertEquals(expected, Money(rupees).format())
    }

    @Test
    fun negativeAmountsUseAMinusSign() {
        assertEquals("−Rs 1,25,000", Money(-125_000).format())
    }

    @Test
    fun formatWithoutSymbol() {
        assertEquals("2,50,000", Money(250_000).format(symbol = false))
    }

    @Test
    fun compactFormat() {
        val cases = listOf(
            500L to "500", 50_000L to "50K", 100_000L to "1 L", 125_000L to "1.25 L",
            2_500_000L to "25 L", 24_000_000L to "2.4 Cr",
        )
        for ((rupees, expected) in cases) assertEquals(expected, Money(rupees).formatCompact())
    }

    @Test
    fun parsesGroupedAndPlainInput() {
        assertEquals(Money(250_000), Money.parse("2,50,000"))
        assertEquals(Money(250_000), Money.parse(" 250000 "))
    }

    @Test
    fun rejectsEmptyDecimalsAndText() {
        assertNull(Money.parse(""))
        assertNull(Money.parse("12.5"))
        assertNull(Money.parse("abc"))
    }

    @Test
    fun slotMathShareTimesMonthsIsThePayout() {
        // REQUIREMENTS section 3: payout per sharer = share x N.
        assertEquals(Money(2_500_000), Money(125_000) * 20)
    }

    @Test
    fun rupeeThousandSteps() {
        assertTrue(Money(63_000).isMultipleOf(Money(1000)))
        assertFalse(Money(62_500).isMultipleOf(Money(1000)))
        assertFalse(Money(1000).isMultipleOf(Money.ZERO))
    }

    @Test
    fun comparisonAndSums() {
        val a = Money(50_000)
        val b = Money(100_000)
        assertEquals(Money(150_000), a + b)
        assertEquals(a, b - a)
        assertTrue(a < b)
        assertTrue((a - b).isNegative)
        assertEquals(a, (-a).abs())
    }

    @Test
    fun decodesFromABareInteger() {
        assertEquals(Money(250_000), Json.decodeFromString<Money>("250000"))
        assertEquals("250000", Json.encodeToString(Money(250_000)))
    }
}
