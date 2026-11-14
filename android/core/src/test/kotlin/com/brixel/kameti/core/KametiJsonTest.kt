package com.brixel.kameti.core

import java.time.Instant
import java.time.LocalDate
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.Serializable

class KametiJsonTest {
    @Serializable
    private data class Row(
        val slotAmount: Money,
        @Serializable(DateOnlySerializer::class) val startMonth: LocalDate,
        @Serializable(InstantSerializer::class) val createdAt: Instant,
        val note: String? = null,
    )

    @Test
    fun decodesSnakeCaseDatesAndBothTimestampShapes() {
        val withFraction = KametiJson.json.decodeFromString<Row>(
            """{"slot_amount":250000,"start_month":"2026-10-01","created_at":"2026-11-09T10:00:00.123456+00:00","extra":1}"""
        )
        assertEquals(Money(250_000), withFraction.slotAmount)
        assertEquals(DateOnly.make(2026, 10), withFraction.startMonth)
        assertEquals(Instant.parse("2026-11-09T10:00:00.123456Z"), withFraction.createdAt)

        val plain = KametiJson.json.decodeFromString<Row>(
            """{"slot_amount":1000,"start_month":"2026-10-01","created_at":"2026-11-09T10:00:00Z"}"""
        )
        assertEquals(Instant.parse("2026-11-09T10:00:00Z"), plain.createdAt)
    }

    @Test
    fun attemptKeepsTheFailure() = runTest {
        assertEquals(Attempt.Success(3), attempt { 3 })
        assertEquals(Attempt.Failed(Failure.Network), attempt<Int> { throw Failure.Network })
        assertIs<Failure.Unknown>((attempt<Int> { error("boom") } as Attempt.Failed).failure)
    }
}
