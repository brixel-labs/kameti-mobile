package com.brixel.kameti.feature.kametidetail

import androidx.compose.ui.graphics.vector.ImageVector
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.ReminderTime
import com.brixel.kameti.domain.AuditEntry
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.ui.KIcons
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.longOrNull

/** One readable line of the activity log (FR-90), built from an audit entry. */
internal data class ActivityItem(
    val id: Long,
    val at: Instant,
    val category: Category,
    val icon: ImageVector,
    val tone: Tone,
    val title: String,
    val detail: String?,
    val changes: List<Change> = emptyList(),
) {
    enum class Category { Money, Members, Changes }
    enum class Tone { Positive, Negative, Info, Warning, Neutral, Brand }

    /** One field that changed in an edit: "Due day: 10th → 12th". */
    data class Change(val label: String, val before: String, val after: String)
}

private operator fun JsonElement?.get(key: String): JsonElement? = (this as? JsonObject)?.get(key)?.takeUnless { it is JsonNull }
private val JsonElement?.text: String? get() = (this as? JsonPrimitive)?.takeIf { it.isString }?.content
private val JsonElement?.number: Long? get() = (this as? JsonPrimitive)?.takeUnless { it.isString }?.longOrNull

/** Turns audit entries into activity rows, and the filters and grouping. */
internal object ActivityLogic {
    enum class Filter { All, Money, Members, Changes }

    /**
     * Names to show, from the kameti's current members plus what the entry
     * itself remembers (a removed member is only in the entry).
     */
    class Context(val members: List<Member>, val slots: List<Slot>, val kameti: Kameti, val strings: Strings) {
        fun name(id: String?, fallback: JsonElement? = null): String =
            members.firstOrNull { it.id == id }?.name ?: fallback["name"].text ?: strings.get(R.string.detail_a_member)

        fun payoutLabel(slotId: String?): String? {
            val slot = slots.firstOrNull { it.id == slotId } ?: return null
            return strings.get(R.string.detail_s_payout, DetailLogic.monthName(DetailLogic.monthStart(kameti, slot.payoutMonthIndex)))
        }
    }

    fun item(entry: AuditEntry, c: Context): ActivityItem {
        val s = c.strings
        val after = entry.after
        val before = entry.before
        val row = after ?: before
        val memberId = entry.memberId ?: row["member_id"].text
        val who = c.name(memberId, fallback = if (entry.entity == "member") row else null)
        val amount = row["amount"].number?.let { Money(it).format() }

        fun make(
            category: ActivityItem.Category, icon: ImageVector, tone: ActivityItem.Tone, title: String, detail: String?,
            changes: List<ActivityItem.Change> = emptyList(),
        ) = ActivityItem(entry.id, entry.at, category, icon, tone, title, detail, changes)

        fun joined(vararg parts: String?): String = parts.filterNotNull().joinToString(" · ")
        fun reason(): String? = after["void_reason"].text?.let { "“$it”" }
        val money = ActivityItem.Category.Money
        val members = ActivityItem.Category.Members
        val changed = ActivityItem.Category.Changes

        return when (entry.action) {
            "payment.record" -> make(
                money, KIcons.check, ActivityItem.Tone.Positive, s.get(R.string.detail_payment_recorded),
                joined(amount?.let { s.get(R.string.detail_s_from_s, it, who) }, methodName(after["method"].text, s)),
            )
            "payment.void" -> make(
                money, KIcons.closeCircle, ActivityItem.Tone.Negative, s.get(R.string.detail_payment_voided),
                joined(amount?.let { s.get(R.string.detail_s_from_s, it, who) }, reason()),
            )
            "payout.record" -> make(
                money, KIcons.arrowUp, ActivityItem.Tone.Warning,
                c.payoutLabel(after["slot_id"].text)?.let { s.get(R.string.detail_s_paid_out, it) } ?: s.get(R.string.detail_payout_recorded),
                amount?.let { s.get(R.string.detail_s_to_s, it, who) },
            )
            "payout.void" -> make(
                money, KIcons.closeCircle, ActivityItem.Tone.Negative, s.get(R.string.detail_payout_voided),
                joined(amount?.let { s.get(R.string.detail_s_to_s, it, who) }, reason()),
            )

            "member.add" -> make(members, KIcons.personAdd, ActivityItem.Tone.Brand, s.get(R.string.detail_s_added, who), null)
            "member.update" -> make(
                members, KIcons.edit, ActivityItem.Tone.Neutral, s.get(R.string.detail_s_s_details_changed, who), null,
                changes(
                    before, after,
                    listOf(
                        Field("name", s.get(R.string.detail_name)) { text(it, s) },
                        Field("nickname", s.get(R.string.detail_nickname)) { text(it, s) },
                    ),
                ),
            )
            "member.remove" -> make(members, KIcons.personOff, ActivityItem.Tone.Negative, s.get(R.string.detail_s_removed, who), null)
            "member.approve_join", "invite.accept" -> make(
                members, KIcons.verified, ActivityItem.Tone.Info, s.get(R.string.detail_s_joined, who),
                s.get(
                    if (entry.action == "member.approve_join") R.string.detail_join_request_approved else R.string.detail_accepted_the_invite,
                ),
            )
            "member.decline_join" ->
                make(members, KIcons.personProblem, ActivityItem.Tone.Negative, s.get(R.string.detail_s_s_join_request_rejected, who), null)
            "member.unlink" ->
                make(members, KIcons.swap, ActivityItem.Tone.Neutral, s.get(R.string.detail_s_unlinked_from_their_account, who), null)
            "invite.create" ->
                make(members, KIcons.envelope, ActivityItem.Tone.Brand, s.get(R.string.detail_invite_sent_to_s, who), after["email"].text)
            "invite.revoke" -> make(members, KIcons.shield, ActivityItem.Tone.Neutral, s.get(R.string.detail_invite_to_s_revoked, who), null)
            "invite.accept_pending_approval" -> make(
                members, KIcons.personWaiting, ActivityItem.Tone.Info, s.get(R.string.detail_s_accepted_with_another_email, who),
                s.get(R.string.detail_waiting_for_approval),
            )
            "invite.decline" ->
                make(members, KIcons.closeCircle, ActivityItem.Tone.Neutral, s.get(R.string.detail_s_declined_the_invite, who), null)

            "kameti.create" -> make(changed, KIcons.plusCircle, ActivityItem.Tone.Brand, s.get(R.string.detail_kameti_created), null)
            "kameti.start" -> make(changed, KIcons.checkCircle, ActivityItem.Tone.Positive, s.get(R.string.detail_kameti_started), null)
            "kameti.update" -> make(
                changed, KIcons.edit, ActivityItem.Tone.Neutral, s.get(R.string.detail_kameti_edited), null,
                changes(
                    before, after,
                    listOf(
                        Field("name", s.get(R.string.detail_name)) { text(it, s) },
                        Field("description", s.get(R.string.detail_description)) { text(it, s) },
                        Field("due_day", s.get(R.string.detail_due_day)) { it.number?.let { day -> ReminderLogic.ordinal(day.toInt()) } ?: "–" },
                        Field("reminder_days", s.get(R.string.detail_reminders)) { days(it, s) },
                        Field("reminder_hour", s.get(R.string.detail_reminder_time)) { it.number?.let { hour -> ReminderTime.label(hour.toInt()) } ?: "–" },
                    ),
                ),
            )
            "slot.set_shares" -> make(
                changed, KIcons.people, ActivityItem.Tone.Neutral,
                c.payoutLabel(entry.entityId)?.let { s.get(R.string.detail_shares_changed_on_the_s, it) }
                    ?: s.get(R.string.detail_slot_shares_changed),
                null,
            )
            "slot.reorder" -> make(changed, KIcons.shuffle, ActivityItem.Tone.Brand, s.get(R.string.detail_payout_order_changed), null)
            "note.add", "note.update", "note.delete" -> make(
                changed, KIcons.note, ActivityItem.Tone.Neutral,
                s.get(
                    when (entry.action) {
                        "note.add" -> R.string.detail_note_added
                        "note.update" -> R.string.detail_note_edited
                        else -> R.string.detail_note_deleted
                    },
                ),
                row["body"].text?.let { if (it.length > 80) it.take(80) + "…" else it },
            )
            else -> make(
                changed, KIcons.clock, ActivityItem.Tone.Neutral,
                entry.action.split(".").joinToString(" ") { word -> word.replaceFirstChar { it.titlecase(Locale.ROOT) } },
                null,
            )
        }
    }

    // Fields

    class Field(val key: String, val label: String, val format: (JsonElement?) -> String)

    private fun text(value: JsonElement?, s: Strings): String = value.text?.takeIf { it.isNotEmpty() } ?: s.get(R.string.detail_none)

    private fun days(value: JsonElement?, s: Strings): String {
        val list = (value as? JsonArray)?.mapNotNull { it.number?.toInt() }?.sorted().orEmpty()
        return if (list.isEmpty()) s.get(R.string.detail_none) else list.joinToString(", ") { ReminderLogic.ordinal(it) }
    }

    /** Only the listed fields that differ between before and after. */
    fun changes(before: JsonElement?, after: JsonElement?, fields: List<Field>): List<ActivityItem.Change> = fields.mapNotNull { field ->
        val old = before[field.key]
        val new = after[field.key]
        if (old == new) null else ActivityItem.Change(field.label, field.format(old), field.format(new))
    }

    private fun methodName(raw: String?, s: Strings): String? = when (raw) {
        "cash" -> s.get(R.string.detail_cash_e5b9)
        "bank" -> s.get(R.string.detail_bank_bf7a)
        "other" -> s.get(R.string.detail_other_3520)
        else -> null
    }

    // Lists

    /** Newest first. */
    fun items(entries: List<AuditEntry>, context: Context): List<ActivityItem> =
        entries.sortedWith(compareByDescending<AuditEntry> { it.at }.thenByDescending { it.id }).map { item(it, context) }

    fun filtered(items: List<ActivityItem>, filter: Filter): List<ActivityItem> = when (filter) {
        Filter.All -> items
        Filter.Money -> items.filter { it.category == ActivityItem.Category.Money }
        Filter.Members -> items.filter { it.category == ActivityItem.Category.Members }
        Filter.Changes -> items.filter { it.category == ActivityItem.Category.Changes }
    }

    /** Rows grouped by Pakistan calendar day, newest day first. */
    fun byDay(items: List<ActivityItem>): List<Pair<LocalDate, List<ActivityItem>>> {
        val groups = mutableListOf<Pair<LocalDate, MutableList<ActivityItem>>>()
        for (item in items) {
            val day = pakistanDay(item.at)
            if (groups.lastOrNull()?.first == day) groups.last().second += item else groups += day to mutableListOf(item)
        }
        return groups
    }

    /** "2:15 PM", Pakistan time. */
    fun time(moment: Instant, locale: Locale = Locale.getDefault()): String =
        DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT).withLocale(locale).format(moment.atZone(ZoneId.of("Asia/Karachi")))
}
