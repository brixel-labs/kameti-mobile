package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.KametiClock
import com.brixel.kameti.domain.Note
import com.brixel.kameti.domain.NoteTarget
import com.brixel.kameti.domain.NoteVisibility
import com.brixel.kameti.domain.Slot
import java.time.Instant
import java.time.LocalDate

/** The Pakistan calendar day a moment falls on. */
internal fun pakistanDay(moment: Instant): LocalDate = moment.atOffset(KametiClock.PAKISTAN).toLocalDate()

/**
 * The rules behind the Notes tab (FR-70 to FR-72), apart from the screens so
 * they can be tested.
 */
internal object NoteLogic {
    enum class Filter { All, Private, Shared }

    /**
     * What a note can be about from the composer: the kameti, a member, or a
     * month's slot. (Payment and payout notes come from those items later.)
     */
    data class Target(val type: NoteTarget, val id: String?, val label: String)

    fun kametiTarget(strings: Strings): Target = Target(NoteTarget.Kameti, null, strings.get(R.string.detail_kameti))

    /** Members to choose from, in member order. */
    fun memberTargets(data: KametiDetailData): List<Target> =
        data.members.map { Target(NoteTarget.Member, it.id, it.name) }

    /** Slots to choose from, in schedule order. */
    fun slotTargets(data: KametiDetailData, strings: Strings): List<Target> =
        data.slots.sortedBy { it.payoutMonthIndex }.map { Target(NoteTarget.Slot, it.id, slotLabel(it, data, strings)) }

    /** "October payout": a slot is named after the month it pays out. */
    fun slotLabel(slot: Slot, data: KametiDetailData, strings: Strings): String = strings.get(
        R.string.detail_s_payout,
        DetailLogic.monthName(DetailLogic.monthStart(data.kameti, slot.payoutMonthIndex)),
    )

    /** What the note is about, as shown after "@". */
    fun targetLabel(note: Note, data: KametiDetailData, strings: Strings): String {
        fun name(memberId: String?) = data.members.firstOrNull { it.id == memberId }?.name
        return when (note.targetType) {
            NoteTarget.Kameti -> strings.get(R.string.detail_kameti)
            NoteTarget.Member -> name(note.targetId) ?: strings.get(R.string.detail_a_member)
            NoteTarget.Slot -> data.slots.firstOrNull { it.id == note.targetId }?.let { slotLabel(it, data, strings) }
                ?: strings.get(R.string.detail_a_slot)
            NoteTarget.Payment -> name(data.payments.firstOrNull { it.id == note.targetId }?.memberId)
                ?.let { strings.get(R.string.detail_payment_from_s, it) } ?: strings.get(R.string.detail_a_payment)
            NoteTarget.Payout -> name(data.payouts.firstOrNull { it.id == note.targetId }?.memberId)
                ?.let { strings.get(R.string.detail_payout_to_s, it) } ?: strings.get(R.string.detail_a_payout)
        }
    }

    private fun matches(note: Note, filter: Filter): Boolean = when (filter) {
        Filter.All -> true
        Filter.Private -> note.visibility == NoteVisibility.Private
        Filter.Shared -> note.visibility == NoteVisibility.Shared
    }

    /**
     * Notes for a filter and a search, newest first. The search matches the
     * text and what the note is about.
     */
    fun visible(notes: List<Note>, filter: Filter, search: String, data: KametiDetailData, strings: Strings): List<Note> {
        val query = search.trim()
        return notes
            .filter { matches(it, filter) }
            .filter {
                query.isEmpty() || it.body.contains(query, ignoreCase = true) ||
                    targetLabel(it, data, strings).contains(query, ignoreCase = true)
            }
            .sortedByDescending { it.createdAt }
    }

    fun count(notes: List<Note>, filter: Filter): Int = notes.count { matches(it, filter) }

    /** "Today", "Yesterday" or "3 Nov", by the Pakistan calendar day. */
    fun dayText(moment: Instant, today: LocalDate, strings: Strings): String = dayTitle(pakistanDay(moment), today, strings)

    fun dayTitle(day: LocalDate, today: LocalDate, strings: Strings): String = when (day) {
        today -> strings.get(R.string.detail_today)
        today.minusDays(1) -> strings.get(R.string.detail_yesterday)
        else -> DetailLogic.dayMonth(day)
    }
}
