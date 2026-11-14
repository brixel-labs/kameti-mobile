package com.brixel.kameti.domain

import com.brixel.kameti.core.Day
import com.brixel.kameti.core.Money
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Matches `public.month_payment_status`. */
@Serializable
enum class MonthStatusCode {
    @SerialName("paid") Paid,
    @SerialName("partial") Partial,
    @SerialName("unpaid") Unpaid,
    @SerialName("overdue") Overdue,
    @SerialName("advance") Advance,
    @SerialName("upcoming") Upcoming,
}

/** Matches `public.month_collection_state`. */
@Serializable
enum class MonthCollectionState {
    @SerialName("upcoming") Upcoming,
    @SerialName("collecting") Collecting,
    @SerialName("fully_collected") FullyCollected,
    @SerialName("partially_paid_out") PartiallyPaidOut,
    @SerialName("paid_out") PaidOut,
    @SerialName("paid_out_short") PaidOutShort,
}

/**
 * Row of the `member_balances` view. Balances are calculated by the
 * backend, never stored or recomputed on the device.
 */
@Serializable
data class MemberBalanceRow(
    val kametiId: String,
    val memberId: String,
    val currentMonthIndex: Int,
    val monthlyDue: Money,
    val dueToDate: Money,
    val totalPaid: Money,
    val balance: Money,
    val owes: Money,
    val credit: Money,
)

/** Row of the `member_month_status` view. */
@Serializable
data class MemberMonthRow(
    val kametiId: String,
    val memberId: String,
    val monthIndex: Int,
    val monthStart: Day,
    val isCurrent: Boolean,
    val due: Money,
    val allocated: Money,
    val remaining: Money,
    val status: MonthStatusCode,
)

/** Row of the `month_collection` view: received (cash) vs covered (dues). */
@Serializable
data class MonthCollectionRow(
    val kametiId: String,
    val monthIndex: Int,
    val monthStart: Day,
    val isCurrent: Boolean,
    val target: Money,
    val received: Money,
    val covered: Money,
    val paidCount: Int,
    val memberCount: Int,
    val payoutShortfall: Money,
    val paidOut: Money,
    val recipients: Int,
    val recipientsPaid: Int,
    val paidOutShortBy: Money,
    val state: MonthCollectionState,
)
