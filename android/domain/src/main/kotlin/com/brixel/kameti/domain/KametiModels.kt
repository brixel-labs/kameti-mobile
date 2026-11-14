package com.brixel.kameti.domain

import com.brixel.kameti.core.Day
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.ReminderTime
import com.brixel.kameti.core.Timestamp
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class KametiStatus {
    @SerialName("draft") Draft,
    @SerialName("active") Active,
    @SerialName("completed") Completed,
    @SerialName("archived") Archived,
    @SerialName("cancelled") Cancelled,
}

@Serializable
enum class JoinStatus {
    @SerialName("not_invited") NotInvited,
    @SerialName("invited") Invited,
    @SerialName("pending_approval") PendingApproval,
    @SerialName("joined") Joined,
    @SerialName("declined") Declined,
}

/** Row of `public.kametis`. */
@Serializable
data class Kameti(
    val id: String,
    val ownerId: String,
    val name: String,
    val description: String? = null,
    val startMonth: Day,
    val monthsN: Int,
    val slotAmountC: Money,
    val dueDay: Int,
    val reminderDays: List<Int>,
    val maxSlotsPerMember: Int,
    val status: KametiStatus,
    val startedAt: Timestamp? = null,
    /** The hour of the day, Pakistan time, its reminders go out (06 to 22). A backend without the column sends none. */
    val reminderHour: Int = ReminderTime.DEFAULT_HOUR,
) {
    /** The monthly pot: N × C. */
    val pot: Money get() = slotAmountC * monthsN

    fun isOwnedBy(userId: String?): Boolean = userId != null && ownerId == userId
}

/** Row of `public.members`. */
@Serializable
data class Member(
    val id: String,
    val kametiId: String,
    val name: String,
    val joinStatus: JoinStatus,
    val contactId: String? = null,
    val profileId: String? = null,
    val nickname: String? = null,
    val color: String? = null,
    /**
     * The owner marked this member as not using the app: they get their updates by WhatsApp, and nobody
     * waits for them to join. Never true for a member who has an invite or has joined. A backend
     * without the column sends none.
     */
    val noApp: Boolean = false,
)

/** Row of `public.slots`. Created automatically, one per month. */
@Serializable
data class Slot(
    val id: String,
    val kametiId: String,
    val payoutMonthIndex: Int,
    val note: String? = null,
)

/** Row of `public.shares`. */
@Serializable
data class Share(
    val id: String,
    val kametiId: String,
    val slotId: String,
    val memberId: String,
    val monthlyAmount: Money,
    val effectiveFromMonth: Int,
    val effectiveToMonth: Int? = null,
)

/** Input for `set_slot_shares`. */
data class ShareInput(val memberId: String, val monthlyAmount: Money)

/** Input for `create_kameti`. */
data class NewKameti(
    val name: String,
    val startMonth: Day,
    val months: Int,
    val slotAmount: Money,
    val dueDay: Int = 10,
    val reminderDays: List<Int> = listOf(1, 5, 8, 10),
    val maxSlotsPerMember: Int = 4,
    val description: String? = null,
    val reminderHour: Int = ReminderTime.DEFAULT_HOUR,
)

/** Input for `update_kameti_draft`. `null` leaves a field unchanged. */
data class KametiChanges(
    val name: String? = null,
    val description: String? = null,
    val startMonth: Day? = null,
    val months: Int? = null,
    val slotAmount: Money? = null,
    val dueDay: Int? = null,
    val reminderDays: List<Int>? = null,
    val maxSlotsPerMember: Int? = null,
    val reminderHour: Int? = null,
)

/** Input for `add_member`. */
data class NewMember(
    val name: String? = null,
    val contactId: String? = null,
    val email: String? = null,
    val phone: String? = null,
    val nickname: String? = null,
    val isSelf: Boolean = false,
)

/**
 * Input for `update_member`. `null` leaves a field unchanged; an empty
 * string clears it.
 */
data class MemberChanges(
    val name: String? = null,
    val nickname: String? = null,
    val email: String? = null,
    val phone: String? = null,
    val noApp: Boolean? = null,
)
