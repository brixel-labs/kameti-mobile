package com.brixel.kameti.domain

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.get
import com.brixel.kameti.core.longValue
import com.brixel.kameti.core.stringValue
import java.time.Duration
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Rows shaped exactly as PostgREST returns them (snake_case, bigint as int,
 * dates as YYYY-MM-DD, timestamps as ISO-8601).
 */
class ModelDecodingTest {
    private inline fun <reified T> decode(json: String): T = KametiJson.json.decodeFromString<T>(json)

    @Test
    fun theReminderHourDecodes() {
        val k = decode<Kameti>(
            """
            {"id":"k1","owner_id":"u1","name":"Office Kameti 2026","description":null,
             "start_month":"2026-10-01","months_n":20,"slot_amount_c":250000,"due_day":10,
             "reminder_days":[1,5,8,10],"reminder_hour":18,"max_slots_per_member":6,"status":"active"}
            """
        )
        assertEquals(18, k.reminderHour)
    }

    @Test
    fun kameti() {
        val k = decode<Kameti>(
            """
            {"id":"k1","owner_id":"u1","name":"Office Kameti 2026","description":null,
             "start_month":"2026-10-01","months_n":20,"slot_amount_c":250000,"due_day":10,
             "reminder_days":[1,5,8,10],"max_slots_per_member":6,"status":"active",
             "privacy_settings":{"show_amounts":true},
             "created_at":"2026-11-09T19:59:09.123+00:00","started_at":"2026-11-09T20:00:00+00:00"}
            """
        )
        assertEquals(Money(250_000), k.slotAmountC)
        assertEquals(Money(5_000_000), k.pot)
        assertEquals(DateOnly.make(2026, 10), k.startMonth)
        assertEquals(KametiStatus.Active, k.status)
        assertNotNull(k.startedAt)
        // This row came from a backend without the reminder-hour column: reminders stay at 10.
        assertEquals(10, k.reminderHour)
        assertTrue(k.isOwnedBy("u1"))
        assertFalse(k.isOwnedBy("u2"))
        assertFalse(k.isOwnedBy(null))
    }

    @Test
    fun memberAndShare() {
        val m = decode<Member>(
            """
            {"id":"m1","kameti_id":"k1","name":"Ali Raza","join_status":"pending_approval",
             "contact_id":null,"profile_id":null}
            """
        )
        assertEquals(JoinStatus.PendingApproval, m.joinStatus)
        // This row came from a backend without the no_app column: the member uses the app.
        assertEquals(false, m.noApp)
        val guest = decode<Member>(
            """
            {"id":"m2","kameti_id":"k1","name":"Hira Malik","join_status":"not_invited",
             "contact_id":null,"profile_id":null,"no_app":true}
            """
        )
        assertEquals(true, guest.noApp)

        val s = decode<Share>(
            """
            {"id":"s1","kameti_id":"k1","slot_id":"sl1","member_id":"m1",
             "monthly_amount":125000,"effective_from_month":1,"effective_to_month":null}
            """
        )
        assertEquals(Money(125_000), s.monthlyAmount)
        assertNull(s.effectiveToMonth)
    }

    @Test
    fun paymentWithBankTransferAndVoid() {
        val p = decode<Payment>(
            """
            {"id":"p1","kameti_id":"k1","member_id":"m1","amount":450000,
             "received_on":"2026-11-09","method":"bank_transfer",
             "created_at":"2026-11-09T10:00:00+00:00",
             "voided_at":"2026-11-09T11:00:00+00:00","void_reason":"wrong member"}
            """
        )
        assertEquals(PaymentMethod.BankTransfer, p.method)
        assertEquals(DateOnly.make(2026, 11, 9), p.receivedOn)
        assertTrue(p.isVoided)
    }

    @Test
    fun ledgerViewRows() {
        val c = decode<MonthCollectionRow>(
            """
            {"kameti_id":"k1","month_index":1,"month_start":"2026-10-01","is_current":false,
             "target":5000000,"received":4970000,"covered":4845000,"paid_count":11,
             "member_count":15,"payout_shortfall":30000,"paid_out":4970000,"recipients":1,
             "recipients_paid":1,"paid_out_short_by":30000,"state":"paid_out_short"}
            """
        )
        assertEquals(MonthCollectionState.PaidOutShort, c.state)
        assertEquals(Money(30_000), c.payoutShortfall)
        // Received is the cash; covered is what the oldest-due-first allocation
        // covers (money-and-ledger rule 4).
        assertNotEquals(c.received, c.covered)

        val m = decode<MemberMonthRow>(
            """
            {"kameti_id":"k1","member_id":"m1","month_index":3,"month_start":"2026-12-01",
             "is_current":false,"due":375000,"allocated":180000,"remaining":195000,"status":"advance"}
            """
        )
        assertEquals(MonthStatusCode.Advance, m.status)

        val b = decode<MemberBalanceRow>(
            """
            {"kameti_id":"k1","member_id":"m1","current_month_index":2,"monthly_due":125000,
             "due_to_date":250000,"total_paid":300000,"balance":-50000,"owes":0,"credit":50000}
            """
        )
        assertEquals(Money(50_000), b.credit)
        assertTrue(b.balance.isNegative)
    }

    @Test
    fun timestampsWithAndWithoutFractionalSeconds() {
        val a = decode<Payment>(
            """
            {"id":"p","kameti_id":"k","member_id":"m","amount":1,"received_on":"2026-11-09",
             "method":"cash","created_at":"2026-11-09T19:59:09.123+00:00"}
            """
        )
        val b = decode<Payment>(
            """
            {"id":"p","kameti_id":"k","member_id":"m","amount":1,"received_on":"2026-11-09",
             "method":"cash","created_at":"2026-11-09T19:59:09+00:00"}
            """
        )
        assertTrue(Duration.between(b.createdAt, a.createdAt).abs() < Duration.ofSeconds(1))
    }

    @Test
    fun inviteRows() {
        val preview = decode<InvitePreview>(
            """
            {"invite_id":"i1","status":"pending","expired":false,"expires_at":"2026-11-24T10:00:00+00:00",
             "email_matches":false,"kameti_name":"Office Kameti","owner_name":"Hassan",
             "member_name":"Ali Raza","shares":[{"payout_month_index":3,"monthly_amount":50000}]}
            """
        )
        assertTrue(preview.isOpen)
        assertTrue(preview.canJoin)
        assertEquals(Money(50_000), preview.shares.first().monthlyAmount)

        val link = decode<InviteLink>(
            """
            {"invite_id":"i1","member_id":"m1","email":"a@b.co","token":"t","code":"K7Q2MX",
             "link":"https://www.fhbtechservices.com/kameti/join/t","expires_at":"2026-11-24T10:00:00+00:00"}
            """
        )
        assertEquals("K7Q2MX", link.code)

        val invite = decode<Invite>(
            """
            {"id":"i1","kameti_id":"k1","member_id":"m1","status":"pending",
             "expires_at":"2026-11-24T10:00:00+00:00","send_count":1}
            """
        )
        assertFalse(invite.isExpired(invite.expiresAt.minusSeconds(60)))
        assertTrue(invite.isExpired(invite.expiresAt.plusSeconds(60)))
    }

    @Test
    fun auditEntryKeepsFreeFormJson() {
        val e = decode<AuditEntry>(
            """
            {"id":7,"kameti_id":"k1","member_id":"m1","actor_id":"u1","action":"payment.void",
             "entity":"payment","entity_id":"p1","before":null,
             "after":{"amount":100000,"void_reason":"typo"},"at":"2026-11-09T12:00:00+00:00"}
            """
        )
        assertNull(e.before)
        assertEquals(100_000L, e.after?.get("amount")?.longValue)
        assertEquals("typo", e.after?.get("void_reason")?.stringValue)
    }

    @Test
    fun profileCacheRoundTripsPerAccount() {
        val cache = ProfileCache()
        cache.update("u1") { it.copy(profile = Profile("u1", "Hassan"), namePrompted = true) }
        cache.setSignInMethods("u1", listOf(SignInMethod(SignInMethod.Provider.Google, "a@b.co")))
        val loaded = cache.load("u1")
        assertEquals("Hassan", loaded.profile?.displayName)
        assertEquals(listOf(SignInMethod(SignInMethod.Provider.Google, "a@b.co")), loaded.signInMethods)
        assertNotNull(loaded.savedAt)
        assertEquals(ProfileSnapshot(), cache.load("u2"))
        cache.clear("u1")
        assertEquals(ProfileSnapshot(), cache.load("u1"))
    }
}
