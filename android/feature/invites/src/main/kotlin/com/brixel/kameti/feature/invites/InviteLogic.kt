package com.brixel.kameti.feature.invites

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import java.time.Duration
import java.time.Instant

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
}
