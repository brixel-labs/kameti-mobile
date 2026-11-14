package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MonthCollectionState
import com.brixel.kameti.domain.Payment
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

/**
 * Pure helpers that join the kameti rows (members, slots, shares) for the
 * detail screens and Home's cards. No balance maths here: balances, statuses
 * and totals come from the backend views.
 */
object DetailLogic {
    /** One person paid out in a month: their share × N. */
    data class Recipient(val member: Member, val share: Share, val payout: Money) {
        val id: String get() = share.id
    }

    /** First day of the 1-based [monthIndex] of [kameti]. */
    fun monthStart(kameti: Kameti, monthIndex: Int): LocalDate =
        kameti.startMonth.plusMonths((monthIndex - 1).toLong())

    /** The due date of [monthIndex]: the kameti's due day in that month. */
    fun dueDate(kameti: Kameti, monthIndex: Int): LocalDate =
        monthStart(kameti, monthIndex).plusDays((kameti.dueDay - 1).toLong())

    /** "10 Nov". */
    fun dayMonth(date: LocalDate, locale: Locale = Locale.getDefault()): String =
        date.format(DateTimeFormatter.ofPattern("d MMM", locale))

    /** "October 2026". */
    fun monthTitle(date: LocalDate, locale: Locale = Locale.getDefault()): String =
        date.format(DateTimeFormatter.ofPattern("MMMM yyyy", locale))

    /** "October". */
    fun monthName(date: LocalDate, locale: Locale = Locale.getDefault()): String =
        date.month.getDisplayName(TextStyle.FULL, locale)

    /** The share counts in [monthIndex] (it started and hasn't ended). */
    fun isActive(share: Share, monthIndex: Int): Boolean =
        share.effectiveFromMonth <= monthIndex && (share.effectiveToMonth?.let { it >= monthIndex } ?: true)

    /** Who receives the pot in [monthIndex], from the slot whose payout month it is. */
    fun recipients(
        kameti: Kameti,
        monthIndex: Int,
        slots: List<Slot>,
        shares: List<Share>,
        members: List<Member>,
    ): List<Recipient> {
        val slotIds = slots.filter { it.payoutMonthIndex == monthIndex }.map { it.id }.toSet()
        val byId = members.associateBy { it.id }
        return shares.mapNotNull { share ->
            if (share.slotId !in slotIds || !isActive(share, monthIndex)) return@mapNotNull null
            val member = byId[share.memberId] ?: return@mapNotNull null
            Recipient(member, share, share.monthlyAmount * kameti.monthsN)
        }
    }

    /** The signed-in user's member row, if they are a member. */
    fun myMember(members: List<Member>, userId: String?): Member? =
        if (userId == null) null else members.firstOrNull { it.profileId == userId }

    /** The row for the current month, if the kameti is running. */
    fun currentCollection(rows: List<MonthCollectionRow>): MonthCollectionRow? = rows.firstOrNull { it.isCurrent }

    /** Members who still owe for [monthIndex] (partial, unpaid or overdue). */
    fun owing(months: List<MemberMonthRow>, monthIndex: Int): List<MemberMonthRow> = months.filter {
        it.monthIndex == monthIndex &&
            it.status in setOf(MonthStatusCode.Partial, MonthStatusCode.Unpaid, MonthStatusCode.Overdue)
    }

    data class StatusCounts(val paid: Int = 0, val partial: Int = 0, val unpaid: Int = 0)

    /** Paid (incl. advance), partial and unpaid (incl. overdue) counts for one month. */
    fun statusCounts(months: List<MemberMonthRow>, monthIndex: Int): StatusCounts {
        var paid = 0
        var partial = 0
        var unpaid = 0
        for (row in months) {
            if (row.monthIndex != monthIndex) continue
            when (row.status) {
                MonthStatusCode.Paid, MonthStatusCode.Advance -> paid += 1
                MonthStatusCode.Partial -> partial += 1
                MonthStatusCode.Unpaid, MonthStatusCode.Overdue -> unpaid += 1
                MonthStatusCode.Upcoming -> Unit
            }
        }
        return StatusCounts(paid, partial, unpaid)
    }

    data class Turn(val monthIndex: Int, val payout: Money)

    /** My next payout at or after [monthIndex], with the amount. */
    fun nextTurn(member: Member, kameti: Kameti, monthIndex: Int, slots: List<Slot>, shares: List<Share>): Turn? =
        slots.sortedBy { it.payoutMonthIndex }.firstNotNullOfOrNull { slot ->
            if (slot.payoutMonthIndex < monthIndex) return@firstNotNullOfOrNull null
            val share = shares.firstOrNull {
                it.slotId == slot.id && it.memberId == member.id && isActive(it, slot.payoutMonthIndex)
            } ?: return@firstNotNullOfOrNull null
            Turn(slot.payoutMonthIndex, share.monthlyAmount * kameti.monthsN)
        }

    /** The first month index whose date range contains [date], if any. */
    fun monthIndex(date: LocalDate, kameti: Kameti): Int? = (1..maxOf(kameti.monthsN, 1)).firstOrNull { index ->
        val start = monthStart(kameti, index)
        !date.isBefore(start) && date.isBefore(start.plusMonths(1))
    }

    /** How many slots this member has an active share in. */
    fun slotCount(member: Member, shares: List<Share>): Int =
        shares.filter { it.memberId == member.id && it.effectiveToMonth == null }.map { it.slotId }.toSet().size

    /** The member's stored colour index, else their position in the list. */
    fun colorIndex(member: Member, members: List<Member>): Int =
        member.color?.toIntOrNull() ?: maxOf(members.indexOf(member), 0)

    /** Newest first: by received date, then by when it was recorded. */
    fun newestFirst(payments: List<Payment>): List<Payment> =
        payments.sortedWith(compareByDescending<Payment> { it.receivedOn }.thenByDescending { it.createdAt })

    /** "Bank · ref 88213 · paid by Hassan". */
    fun paymentSubtitle(payment: Payment, methodLabel: String, paidBy: (String) -> String): String = buildList {
        add(methodLabel)
        payment.reference?.takeIf { it.isNotEmpty() }?.let(::add)
        payment.paidByName?.takeIf { it.isNotEmpty() }?.let { add(paidBy(it)) }
    }.joinToString(" · ")

    /**
     * Totals for a kameti whose months are all over (no current month, but
     * collections exist). `null` while it hasn't started.
     */
    data class FinalSummary(
        val firstMonth: LocalDate,
        val lastMonth: LocalDate,
        val months: Int,
        val collected: Money,
        val paidOut: Money,
        val monthsPaidOut: Int,
        /** Members who still owe, largest first. */
        val owing: List<MemberBalanceRow>,
        /** Members left with credit, largest first. */
        val credit: List<MemberBalanceRow>,
    ) {
        val isSettled: Boolean get() = owing.isEmpty() && credit.isEmpty()
    }

    fun finalSummary(data: KametiDetailData): FinalSummary? {
        if (data.current != null || data.kameti.status == KametiStatus.Draft) return null
        val first = data.collections.minByOrNull { it.monthIndex } ?: return null
        val last = data.collections.maxByOrNull { it.monthIndex } ?: return null
        if (last.monthStart.isAfter(data.today)) return null
        return FinalSummary(
            firstMonth = first.monthStart,
            lastMonth = last.monthStart,
            months = data.kameti.monthsN,
            collected = data.collections.fold(Money.ZERO) { sum, row -> sum + row.received },
            paidOut = data.collections.fold(Money.ZERO) { sum, row -> sum + row.paidOut },
            monthsPaidOut = data.collections.count {
                it.state == MonthCollectionState.PaidOut || it.state == MonthCollectionState.PaidOutShort
            },
            owing = data.balances.filter { it.owes.isPositive }.sortedByDescending { it.owes },
            credit = data.balances.filter { it.credit.isPositive }.sortedByDescending { it.credit },
        )
    }
}

/**
 * "Edit setup" (mirrors `reopen_kameti`): the owner can take a started kameti
 * back to setup until its first month arrives, while nothing is recorded.
 */
object SetupLogic {
    fun canEditSetup(data: KametiDetailData): Boolean =
        data.isOwner && data.kameti.status == KametiStatus.Active &&
            data.today.isBefore(data.kameti.startMonth) &&
            data.payments.isEmpty() && data.payouts.isEmpty() &&
            data.shares.none { it.effectiveFromMonth > 1 || it.effectiveToMonth != null }
}

/** Name and start month for a duplicated kameti (FR-13). */
object DuplicateLogic {
    /**
     * "Office Kameti (copy)", then "(copy 2)", … kept within the 40-character
     * limit. [suffix] is " (copy)" for the first attempt, " (copy 2)" after.
     */
    fun name(original: String, suffix: String): String =
        original.trim().take(maxOf(40 - suffix.length, 3)).trim() + suffix

    /** The month after the original's last month, or [currentMonth] if that is later. */
    fun startMonth(kameti: Kameti, currentMonth: LocalDate): LocalDate =
        maxOf(DetailLogic.monthStart(kameti, kameti.monthsN + 1), currentMonth)
}
