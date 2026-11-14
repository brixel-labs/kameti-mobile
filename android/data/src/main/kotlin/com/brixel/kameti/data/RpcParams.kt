package com.brixel.kameti.data

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.ReminderTime
import com.brixel.kameti.domain.BatchPaymentItem
import com.brixel.kameti.domain.KametiChanges
import com.brixel.kameti.domain.MemberChanges
import com.brixel.kameti.domain.NewKameti
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.domain.NewNote
import com.brixel.kameti.domain.NewPayment
import com.brixel.kameti.domain.NewPayout
import com.brixel.kameti.domain.NoteTarget
import com.brixel.kameti.domain.NoteVisibility
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.domain.ShareInput
import java.time.LocalDate
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.encodeToJsonElement

/**
 * RPC arguments, one pure builder per call, so what we send to Postgres is
 * unit-tested without a network. Keys are the backend's `p_*` names.
 */
internal typealias RpcParams = JsonObject

internal fun params(vararg pairs: Pair<String, JsonElement>): RpcParams = JsonObject(mapOf(*pairs))

internal fun text(value: String): JsonElement = JsonPrimitive(value)
internal fun number(value: Int): JsonElement = JsonPrimitive(value)
internal fun rupees(value: Money): JsonElement = JsonPrimitive(value.rupees)
internal fun flag(value: Boolean): JsonElement = JsonPrimitive(value)
internal fun day(value: LocalDate): JsonElement = JsonPrimitive(DateOnly.string(value))
internal fun texts(values: List<String>): JsonElement = JsonArray(values.map(::JsonPrimitive))
internal fun numbers(values: List<Int>): JsonElement = JsonArray(values.map(::JsonPrimitive))

/** `null` is sent as JSON null, which the backend reads as "leave unchanged". */
internal fun opt(value: String?): JsonElement = value?.let(::JsonPrimitive) ?: JsonNull
internal fun opt(value: Int?): JsonElement = value?.let(::JsonPrimitive) ?: JsonNull
internal fun opt(value: Money?): JsonElement = value?.let(::rupees) ?: JsonNull
internal fun opt(value: LocalDate?): JsonElement = value?.let(::day) ?: JsonNull

/** An enum as the backend spells it (`bank_transfer`, `shared`…). */
internal fun raw(value: PaymentMethod): JsonElement = KametiJson.json.encodeToJsonElement(value)
internal fun raw(value: NoteVisibility): JsonElement = KametiJson.json.encodeToJsonElement(value)
internal fun raw(value: NoteTarget): JsonElement = KametiJson.json.encodeToJsonElement(value)

internal object Params {
    fun addNote(kametiId: String, n: NewNote): RpcParams = params(
        "p_kameti_id" to text(kametiId),
        "p_body" to text(n.body),
        "p_visibility" to raw(n.visibility),
        "p_target_type" to raw(n.targetType),
        "p_target_id" to opt(if (n.targetType == NoteTarget.Kameti) null else n.targetId),
    )

    fun updateNote(id: String, body: String?, visibility: NoteVisibility?): RpcParams = params(
        "p_note_id" to text(id),
        "p_body" to opt(body),
        "p_visibility" to (visibility?.let(::raw) ?: JsonNull),
    )

    fun createKameti(new: NewKameti): RpcParams = JsonObject(
        mapOf(
            "p_name" to text(new.name),
            "p_start_month" to day(new.startMonth),
            "p_months_n" to number(new.months),
            "p_slot_amount_c" to rupees(new.slotAmount),
            "p_due_day" to number(new.dueDay),
            "p_reminder_days" to numbers(new.reminderDays),
            "p_max_slots_per_member" to number(new.maxSlotsPerMember),
            "p_description" to opt(new.description),
        ) +
            // Left out when it is the default (10), which the backend uses anyway, so a backend
            // that hasn't got the reminder-hour migration yet still takes the call.
            (if (new.reminderHour != ReminderTime.DEFAULT_HOUR) mapOf("p_reminder_hour" to number(new.reminderHour)) else emptyMap()),
    )

    /** `null` leaves a field unchanged on the backend. */
    fun updateKameti(id: String, c: KametiChanges): RpcParams = JsonObject(
        mapOf(
            "p_kameti_id" to text(id),
            "p_name" to opt(c.name),
            "p_description" to opt(c.description),
            "p_start_month" to opt(c.startMonth),
            "p_months_n" to opt(c.months),
            "p_slot_amount_c" to opt(c.slotAmount),
            "p_due_day" to opt(c.dueDay),
            "p_reminder_days" to (c.reminderDays?.let(::numbers) ?: JsonNull),
            "p_max_slots_per_member" to opt(c.maxSlotsPerMember),
        ) +
            // Only sent when it changes, and left out entirely otherwise, so a backend without the
            // reminder-hour migration still takes the call.
            (c.reminderHour?.let { mapOf("p_reminder_hour" to number(it)) } ?: emptyMap()),
    )

    fun addMember(kametiId: String, m: NewMember): RpcParams = params(
        "p_kameti_id" to text(kametiId),
        "p_name" to opt(m.name),
        "p_contact_id" to opt(m.contactId),
        "p_email" to opt(m.email),
        "p_phone" to opt(m.phone),
        "p_nickname" to opt(m.nickname),
        "p_is_self" to flag(m.isSelf),
    )

    fun updateMember(id: String, c: MemberChanges): RpcParams = params(
        "p_member_id" to text(id),
        "p_name" to opt(c.name),
        "p_nickname" to opt(c.nickname),
        "p_email" to opt(c.email),
        "p_phone" to opt(c.phone),
    )

    fun setSlotShares(slotId: String, shares: List<ShareInput>): RpcParams = params(
        "p_slot_id" to text(slotId),
        "p_shares" to JsonArray(
            shares.map { params("member_id" to text(it.memberId), "monthly_amount" to rupees(it.monthlyAmount)) },
        ),
    )

    fun recordPayment(p: NewPayment): RpcParams = params(
        "p_member_id" to text(p.memberId),
        "p_amount" to rupees(p.amount),
        "p_received_on" to day(p.receivedOn),
        "p_idempotency_key" to text(p.idempotencyKey),
        "p_method" to raw(p.method),
        "p_reference" to opt(p.reference),
        "p_note" to opt(p.note),
        "p_paid_by_name" to opt(p.paidByName),
    )

    fun recordPayments(
        kametiId: String,
        receivedOn: LocalDate,
        items: List<BatchPaymentItem>,
        method: PaymentMethod,
    ): RpcParams = params(
        "p_kameti_id" to text(kametiId),
        "p_received_on" to day(receivedOn),
        "p_items" to JsonArray(items.map(::batchItem)),
        "p_method" to raw(method),
    )

    /** Optional fields are left out, not sent as null. */
    fun batchItem(i: BatchPaymentItem): JsonObject {
        val fields = mutableMapOf(
            "member_id" to text(i.memberId),
            "amount" to rupees(i.amount),
            "idempotency_key" to text(i.idempotencyKey),
        )
        i.paidByName?.let { fields["paid_by_name"] = text(it) }
        i.reference?.let { fields["reference"] = text(it) }
        i.note?.let { fields["note"] = text(it) }
        return JsonObject(fields)
    }

    fun recordPayout(p: NewPayout): RpcParams = params(
        "p_slot_id" to text(p.slotId),
        "p_member_id" to text(p.memberId),
        "p_amount" to rupees(p.amount),
        "p_paid_on" to day(p.paidOn),
        "p_idempotency_key" to text(p.idempotencyKey),
        "p_method" to raw(p.method),
        "p_reference" to opt(p.reference),
        "p_note" to opt(p.note),
    )

    /**
     * `preview_invite`, `accept_invite` and `decline_invite`: exactly one of
     * the token (or the 6-character code) and the invite id.
     */
    fun inviteLookup(token: String?, inviteId: String?): RpcParams =
        params("p_token" to opt(token), "p_invite_id" to opt(inviteId))
}
