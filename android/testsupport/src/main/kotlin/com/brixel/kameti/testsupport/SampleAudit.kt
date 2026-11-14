package com.brixel.kameti.testsupport

import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.domain.AuditEntry
import com.brixel.kameti.domain.AuditRepository
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.Payment
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.domain.Payout
import java.time.Instant
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.put

/**
 * The demo's audit log, shared by the demo stores so whatever you do in the
 * demo shows up in Activity. Seeded with the sample payments and a few
 * realistic events. Payloads use the backend's column names.
 */
class SampleAuditLog {
    private val lock = Any()
    private var entries: List<AuditEntry>
    private var next: Long
    private var tick = 0L

    init {
        val now = SampleData.now
        val seed = mutableListOf<AuditEntry>()
        var id = 1L
        fun add(
            kameti: String, action: String, entity: String, entityId: String?, member: String?, at: Instant,
            before: JsonElement? = null, after: JsonElement? = null,
        ) {
            seed += AuditEntry(
                id = id, kametiId = kameti, action = action, entity = entity, at = at, memberId = member,
                actorId = SampleData.USER_ID, entityId = entityId, before = before, after = after,
            )
            id += 1
        }
        // Every sample payment, recorded on the day it was received.
        for (payment in SampleData.familyPayments + SampleData.friendsPayments + SampleData.officePayments) {
            add(
                payment.kametiId, "payment.record", "payment", payment.id, payment.memberId,
                at = payment.receivedOn.utc().plusSeconds(10 * HOUR), after = payment(payment),
            )
        }
        val october = SampleData.date(10).utc()
        add("family", "kameti.create", "kameti", "family", null, at = SampleData.date(9).utc().plusSeconds(27 * DAY))
        add("family", "kameti.start", "kameti", "family", null, at = october.plusSeconds(9 * HOUR))
        add(
            "family", "note.add", "note", "n4", null, at = now.minusSeconds(40 * DAY),
            after = buildJsonObject { put("body", "Payments by the 10th please. Bank: Meezan, account details in the family group.") },
        )
        add(
            "family", "payout.record", "payout", "fp-oct", "f1", at = october.plusSeconds(11 * DAY + 17 * HOUR),
            after = buildJsonObject { put("amount", 1_500_000); put("member_id", "f1"); put("slot_id", "fs1") },
        )
        add("family", "slot.reorder", "kameti", "family", null, at = october.plusSeconds(2 * DAY + 10 * HOUR))
        add(
            "family", "invite.create", "invite", "inv-f6", "f6", at = now.minusSeconds(2 * DAY),
            after = buildJsonObject { put("member_id", "f6"); put("email", "faisal.iqbal@gmail.com") },
        )
        add("family", "invite.accept_pending_approval", "invite", "inv-f5", "f5", at = now.minusSeconds(DAY).plusSeconds(5 * HOUR))
        fun settings(reminderDays: List<Int>) = buildJsonObject {
            put("name", "Family kameti"); put("due_day", 10)
            put("reminder_days", buildJsonArray { reminderDays.forEach { add(JsonPrimitive(it)) } })
        }
        add(
            "family", "kameti.update", "kameti", "family", null, at = now.minusSeconds(DAY + 4 * HOUR),
            before = settings(listOf(1, 3, 8)), after = settings(listOf(1, 3)),
        )
        entries = seed
        next = id
    }

    /** Adds an entry stamped "now" (a second later each time, so order holds). */
    fun record(
        kametiId: String, action: String, entity: String, entityId: String?, member: String?,
        before: JsonElement? = null, after: JsonElement? = null,
    ): Unit = synchronized(lock) {
        tick += 1
        entries = entries + AuditEntry(
            id = next, kametiId = kametiId, action = action, entity = entity, at = SampleData.now.plusSeconds(tick),
            memberId = member, actorId = SampleData.USER_ID, entityId = entityId, before = before, after = after,
        )
        next += 1
    }

    fun entries(kametiId: String): List<AuditEntry> = synchronized(lock) { entries.filter { it.kametiId == kametiId } }

    companion object {
        // Payloads

        fun payment(p: Payment): JsonElement = buildJsonObject {
            put("amount", p.amount.rupees); put("member_id", p.memberId)
            put("method", KametiJson.json.encodeToJsonElement<PaymentMethod>(p.method))
            p.voidReason?.let { put("void_reason", it) }
        }

        fun payout(p: Payout): JsonElement = buildJsonObject {
            put("amount", p.amount.rupees); put("member_id", p.memberId); put("slot_id", p.slotId)
            p.voidReason?.let { put("void_reason", it) }
        }

        fun kameti(k: Kameti): JsonElement = buildJsonObject {
            put("name", k.name); put("description", k.description); put("due_day", k.dueDay)
            put("reminder_days", buildJsonArray { k.reminderDays.forEach { add(JsonPrimitive(it)) } })
            put("reminder_hour", k.reminderHour)
        }

        fun member(m: Member): JsonElement = buildJsonObject {
            put("name", m.name); put("nickname", m.nickname)
            put("join_status", KametiJson.json.encodeToJsonElement<JoinStatus>(m.joinStatus))
        }
    }
}

/**
 * FR-90 in the demo: the owner reads everything; a member only the
 * entries about them.
 */
class SampleAuditRepository(
    private val log: SampleAuditLog,
    private val kametis: SampleKametiRepository,
) : AuditRepository {
    override suspend fun audit(kametiId: String, limit: Int): List<AuditEntry> {
        val kameti = kametis.kametiRow(kametiId) ?: throw notFound()
        var entries = log.entries(kametiId)
        if (kameti.ownerId != SampleData.USER_ID) {
            val me = kametis.myMember(kametiId)?.id
            entries = entries.filter { me != null && it.memberId == me }
        }
        return entries.sortedByDescending { it.at }.take(limit)
    }
}
