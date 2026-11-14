package com.brixel.kameti.data

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.BatchPaymentItem
import com.brixel.kameti.domain.KametiChanges
import com.brixel.kameti.domain.MemberChanges
import com.brixel.kameti.domain.NewKameti
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.domain.NewNote
import com.brixel.kameti.domain.NewPayment
import com.brixel.kameti.domain.NoteTarget
import com.brixel.kameti.domain.NoteVisibility
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.domain.ShareInput
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull

class ParamsTest {
    @Test
    fun createKametiSendsBackendNamesAndWholeRupees() {
        val p = Params.createKameti(
            NewKameti(name = "Office Kameti", startMonth = DateOnly.make(2026, 10), months = 20, slotAmount = Money(250_000)),
        )
        assertEquals(text("Office Kameti"), p["p_name"])
        assertEquals(text("2026-10-01"), p["p_start_month"])
        assertEquals(number(20), p["p_months_n"])
        assertEquals(rupees(Money(250_000)), p["p_slot_amount_c"])
        assertEquals(numbers(listOf(1, 5, 8, 10)), p["p_reminder_days"])
        assertEquals(JsonNull, p["p_description"])
    }

    @Test
    fun theReminderHourIsLeftOutUntilItIsNotTheDefault() {
        val start = DateOnly.make(2026, 10)
        // The default (10) is what the backend uses anyway, so a backend without the
        // reminder-hour migration still takes the call.
        val plain = Params.createKameti(NewKameti(name = "Office Kameti", startMonth = start, months = 20, slotAmount = Money(250_000)))
        assertTrue("p_reminder_hour" !in plain)
        val evening = Params.createKameti(
            NewKameti(name = "Office Kameti", startMonth = start, months = 20, slotAmount = Money(250_000), reminderHour = 18),
        )
        assertEquals(number(18), evening["p_reminder_hour"])

        assertTrue("p_reminder_hour" !in Params.updateKameti("k1", KametiChanges(dueDay = 12)))
        assertEquals(number(9), Params.updateKameti("k1", KametiChanges(reminderHour = 9))["p_reminder_hour"])
    }

    @Test
    fun updateLeavesUnchangedFieldsNull() {
        val p = Params.updateKameti("k1", KametiChanges(name = "New name", dueDay = 12))
        assertEquals(text("k1"), p["p_kameti_id"])
        assertEquals(text("New name"), p["p_name"])
        assertEquals(number(12), p["p_due_day"])
        assertEquals(JsonNull, p["p_months_n"])
        assertEquals(JsonNull, p["p_slot_amount_c"])
        assertEquals(JsonNull, p["p_start_month"])
        assertEquals(JsonNull, p["p_reminder_days"])
    }

    @Test
    fun noteCalls() {
        val kametiWide = Params.addNote(
            "k1",
            NewNote(body = "Pay by the 10th", visibility = NoteVisibility.Shared, targetType = NoteTarget.Kameti, targetId = "ignored"),
        )
        assertEquals(text("k1"), kametiWide["p_kameti_id"])
        assertEquals(text("Pay by the 10th"), kametiWide["p_body"])
        assertEquals(text("shared"), kametiWide["p_visibility"])
        assertEquals(text("kameti"), kametiWide["p_target_type"])
        assertEquals(JsonNull, kametiWide["p_target_id"]) // a kameti note never sends a target id
        val onMember = Params.addNote("k1", NewNote(body = "x", targetType = NoteTarget.Member, targetId = "m1"))
        assertEquals(text("private"), onMember["p_visibility"])
        assertEquals(text("m1"), onMember["p_target_id"])
        val update = Params.updateNote("n1", body = null, visibility = NoteVisibility.Shared)
        assertEquals(text("n1"), update["p_note_id"])
        assertEquals(JsonNull, update["p_body"])
        assertEquals(text("shared"), update["p_visibility"])
    }

    @Test
    fun memberCalls() {
        val add = Params.addMember("k1", NewMember(name = "Ali", email = "a@b.co", isSelf = false))
        assertEquals(text("Ali"), add["p_name"])
        assertEquals(text("a@b.co"), add["p_email"])
        assertEquals(JsonNull, add["p_contact_id"])
        assertEquals(flag(false), add["p_is_self"])

        // An empty string clears a field on the backend; null leaves it.
        val update = Params.updateMember("m1", MemberChanges(nickname = ""))
        assertEquals(text(""), update["p_nickname"])
        assertEquals(JsonNull, update["p_name"])
    }

    @Test
    fun sharesAreWholeRupeeObjects() {
        val p = Params.setSlotShares("s1", listOf(ShareInput("m1", Money(125_000))))
        assertEquals(
            JsonArray(listOf(params("member_id" to text("m1"), "monthly_amount" to rupees(Money(125_000))))),
            p["p_shares"],
        )
    }

    @Test
    fun paymentAndBatch() {
        val day = DateOnly.make(2026, 11, 9)
        val single = Params.recordPayment(
            NewPayment(
                memberId = "m1", amount = Money(50_000), receivedOn = day, idempotencyKey = "key-1",
                method = PaymentMethod.BankTransfer, paidByName = "Hassan",
            ),
        )
        assertEquals(text("2026-11-09"), single["p_received_on"])
        assertEquals(text("bank_transfer"), single["p_method"])
        assertEquals(text("Hassan"), single["p_paid_by_name"])
        assertEquals(JsonNull, single["p_reference"])

        // Batch lines leave optional fields out instead of sending null.
        val item = Params.batchItem(BatchPaymentItem(memberId = "m1", amount = Money(50_000), idempotencyKey = "key-1"))
        assertEquals(
            params("member_id" to text("m1"), "amount" to rupees(Money(50_000)), "idempotency_key" to text("key-1")),
            item,
        )
    }

    @Test
    fun inviteLookupSendsExactlyOneSide() {
        val byToken = Params.inviteLookup(token = "K7Q2MX", inviteId = null)
        assertEquals(text("K7Q2MX"), byToken["p_token"])
        assertEquals(JsonNull, byToken["p_invite_id"])
        val byId = Params.inviteLookup(token = null, inviteId = "i1")
        assertEquals(text("i1"), byId["p_invite_id"])
    }

    @Test
    fun paramsEncodeToPlainJson() {
        assertEquals("""{"p_slot_id":"s1","p_shares":[]}""", Params.setSlotShares("s1", emptyList()).toString())
    }
}

class SignInNonceTest {
    @Test
    fun hashIsTheSha256OfTheRawValue() {
        // SHA-256("abc"), the standard test vector.
        assertEquals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", SignInNonce("abc").hashed)
    }

    @Test
    fun eachNonceIsFreshAndUrlSafe() {
        val a = SignInNonce.make()
        val b = SignInNonce.make()
        assertNotEquals(a, b)
        assertTrue(a.raw.length >= 40)
        assertTrue(a.raw.all { it.isLetterOrDigit() || it == '-' || it == '_' })
        assertEquals(SignInNonce(a.raw).hashed, a.hashed)
    }
}
