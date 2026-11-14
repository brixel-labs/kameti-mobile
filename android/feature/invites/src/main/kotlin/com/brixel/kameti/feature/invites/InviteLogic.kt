package com.brixel.kameti.feature.invites

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.InvitePreview
import com.brixel.kameti.domain.InviteShare
import com.brixel.kameti.ui.KDates
import java.time.Duration
import java.time.Instant
import java.time.LocalDate

/**
 * Small rules shared by the invite screens, kept apart from the screens so
 * they can be tested.
 */
object InviteLogic {
    /** How long an invite has left, before it is put into words. */
    sealed interface Expiry {
        data object Expired : Expiry
        data object Today : Expiry
        data object Tomorrow : Expiry
        data class InDays(val days: Int) : Expiry
    }

    /** Whole days left before [expiresAt] (0 on the last day, never negative). */
    fun daysLeft(expiresAt: Instant, now: Instant): Int =
        maxOf(Math.floorDiv(Duration.between(now, expiresAt).seconds, 86_400L).toInt(), 0)

    fun expiry(expiresAt: Instant, now: Instant): Expiry {
        if (!expiresAt.isAfter(now)) return Expiry.Expired
        return when (val days = daysLeft(expiresAt, now)) {
            0 -> Expiry.Today
            1 -> Expiry.Tomorrow
            else -> Expiry.InDays(days)
        }
    }

    /** "Expires in 12 days", "Expires tomorrow", "Expires today" or "Expired". */
    @Composable
    fun expiryText(expiresAt: Instant, now: Instant): String = when (val expiry = expiry(expiresAt, now)) {
        Expiry.Expired -> stringResource(R.string.invites_expired)
        Expiry.Today -> stringResource(R.string.invites_expires_today)
        Expiry.Tomorrow -> stringResource(R.string.invites_expires_tomorrow)
        is Expiry.InDays -> stringResource(R.string.invites_expires_in_n_days, expiry.days)
    }

    /** "MH" for "Muhammad Hassan": the first letters of the first two words. */
    fun initials(name: String): String =
        name.split(" ").filter { it.isNotEmpty() }.take(2).joinToString("") { it.take(1) }.uppercase()

    /** Why this account can't join (E39). */
    sealed interface Blocked {
        /** The signed-in account runs this kameti. */
        data object Owner : Blocked

        /** Already in the kameti, on the member record with this name. */
        data class AlreadyMember(val name: String, val ownerName: String) : Blocked
    }

    /** Why this account can't join, to say up front, or `null`. */
    fun blocked(preview: InvitePreview): Blocked? = when {
        preview.isOwner == true -> Blocked.Owner
        preview.alreadyMember == true -> Blocked.AlreadyMember(preview.alreadyMemberName ?: "", preview.ownerName)
        else -> null
    }

    @Composable
    fun blockedReason(preview: InvitePreview): String? = when (val reason = blocked(preview)) {
        Blocked.Owner -> stringResource(R.string.invites_you_run_this_kameti_so_you_cant_join)
        is Blocked.AlreadyMember ->
            stringResource(R.string.invites_youre_already_a_member_of_this_kameti_as, reason.name, reason.ownerName)
        null -> null
    }

    /** What the invitee pays each month: the sum of their shares. */
    fun monthlyTotal(shares: List<InviteShare>): Money = shares.fold(Money.ZERO) { sum, share -> sum + share.monthlyAmount }

    /** What the invitee receives in all: each share × N months. */
    fun payout(shares: List<InviteShare>, monthsN: Int): Money =
        shares.fold(Money.ZERO) { sum, share -> sum + share.monthlyAmount * monthsN }

    /** The payout months the invitee has a turn in, in order. */
    fun turnMonths(shares: List<InviteShare>): List<Int> = shares.map { it.payoutMonthIndex }.distinct().sorted()

    /** The first day of month [index] (1-based). */
    fun monthStart(start: LocalDate, index: Int): LocalDate = start.plusMonths((index - 1).toLong())

    /**
     * "January 2027 · Month 3", or "Jan 2027 and Mar 2027" for more than one
     * turn. Without a start month: "Month 3" or "Months 2 and 4".
     */
    @Composable
    fun turnsText(shares: List<InviteShare>, startMonth: LocalDate? = null): String? {
        val months = turnMonths(shares)
        val last = months.lastOrNull() ?: return null
        if (startMonth != null) {
            if (months.size == 1) {
                return stringResource(R.string.invites_s_month_n, KDates.monthLabel(monthStart(startMonth, last)), last)
            }
            val names = months.map { KDates.shortMonthLabel(monthStart(startMonth, it)) }
            return stringResource(R.string.invites_s_and_s, names.dropLast(1).joinToString(", "), names.last())
        }
        if (months.size == 1) return stringResource(R.string.invites_month_n, last)
        return stringResource(R.string.invites_months_s_and_n, months.dropLast(1).joinToString(", "), last)
    }

    /** "Nov 2026 → Feb 2027": the first and last month. */
    fun runsText(startMonth: LocalDate, monthsN: Int): String =
        "${KDates.shortMonthLabel(startMonth)} → ${KDates.shortMonthLabel(monthStart(startMonth, monthsN))}"

    /** Hides most of an email: `x7••••••••@privaterelay.appleid.com`. */
    fun masked(email: String): String {
        val at = email.indexOf('@')
        if (at < 0) return email
        val name = email.substring(0, at)
        val visible = name.take(2)
        return visible + "•".repeat(maxOf(name.length - visible.length, 3)) + email.substring(at)
    }
}
