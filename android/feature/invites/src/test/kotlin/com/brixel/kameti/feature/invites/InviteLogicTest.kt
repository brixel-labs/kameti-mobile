package com.brixel.kameti.feature.invites

import com.brixel.kameti.feature.invites.InviteLogic.Expiry
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals

class InviteLogicTest {
    private val now = Instant.parse("2026-11-10T00:00:00Z")

    @Test
    fun expiryReadsInDays() {
        assertEquals(Expiry.InDays(12), InviteLogic.expiry(now.plusSeconds(12 * 86_400 + 60), now))
        assertEquals(Expiry.Tomorrow, InviteLogic.expiry(now.plusSeconds(86_400 + 60), now))
        assertEquals(Expiry.Today, InviteLogic.expiry(now.plusSeconds(3600), now))
        assertEquals(Expiry.Expired, InviteLogic.expiry(now.minusSeconds(1), now))
    }

    @Test
    fun initialsTakeTheFirstTwoWords() {
        assertEquals("MH", InviteLogic.initials("Muhammad Hassan"))
        assertEquals("A", InviteLogic.initials("ali"))
        assertEquals("AB", InviteLogic.initials("Ayesha  Bibi Khan"))
    }
}
