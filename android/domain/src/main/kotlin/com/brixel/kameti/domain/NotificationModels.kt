package com.brixel.kameti.domain

import com.brixel.kameti.core.Money
import com.brixel.kameti.core.Timestamp
import java.time.Instant
import kotlinx.serialization.Serializable

/**
 * Row of `public.notifications`: one thing that happened, for one person
 * (FR-83, FR-86). The Inbox's Updates list; also what was pushed.
 */
@Serializable
data class AppNotification(
    val id: String,
    val kametiId: String? = null,
    /** e.g. `payment`, `payout`, `joined`, `join_request`, `invite`. */
    val kind: String,
    /** `reminders`, `payments`, `invites`, `changes` or `broadcast`. */
    val category: String,
    val title: String,
    val body: String,
    val readAt: Timestamp? = null,
    val createdAt: Timestamp,
) {
    val isUnread: Boolean get() = readAt == null

    /**
     * Whether tapping it should open its kameti. Not for an invitation (not
     * joined yet), a join request (answered from the Inbox) or a declined
     * join (that person can't see the kameti).
     */
    val opensKameti: Boolean get() = opensKameti(kind) && kametiId != null

    /** The same notification, marked read now. */
    fun markedRead(at: Instant): AppNotification = copy(readAt = at)

    companion object {
        fun opensKameti(kind: String): Boolean = kind !in setOf("invite", "join_request", "join_declined")

        /** Columns the app reads (the table has more, for the push sender). */
        const val COLUMNS = "id, kameti_id, kind, category, title, body, read_at, created_at"
    }
}

/** What the user wants pushed (FR-85). Everything still reaches the Inbox. */
@Serializable
data class NotificationPreferences(
    val notifyReminders: Boolean = true,
    val notifyPayments: Boolean = true,
    val notifyInvites: Boolean = true,
    val notifyChanges: Boolean = true,
) {
    companion object {
        const val COLUMNS = "notify_reminders, notify_payments, notify_invites, notify_changes"
    }
}

/** Who an owner's reminder would reach (`reminder_targets`, FR-82, FR-84). */
@Serializable
data class ReminderTargets(val dueDay: Int, val members: List<Member>) {
    @Serializable
    data class Member(
        val memberId: String,
        val name: String,
        val owed: Money,
        /** Joined the app: gets the push. Otherwise remind on WhatsApp. */
        val hasApp: Boolean,
        /** The owner already reminded them today (one owner reminder a day each). */
        val remindedToday: Boolean = false,
        val phone: String? = null,
    ) {
        val id: String get() = memberId
    }
}

/** What a reminder did: how many got it, and who was skipped (already reminded today). */
@Serializable
data class ReminderResult(val sent: Int, val skipped: List<String> = emptyList())

/** The signed-in user's notifications, devices and preferences. */
interface NotificationsRepository {
    /** Newest first. */
    suspend fun notifications(limit: Int): List<AppNotification>

    /** Marks these read, or every unread one when [ids] is null. */
    suspend fun markRead(ids: List<String>?)

    /** Saves this phone's push token for the signed-in account. */
    suspend fun registerDevice(token: String, platform: String)
    suspend fun unregisterDevice(token: String)
    suspend fun preferences(userId: String): NotificationPreferences
    suspend fun updatePreferences(userId: String, preferences: NotificationPreferences)

    /** Owner only: who owes now, with and without the app. */
    suspend fun reminderTargets(kametiId: String): ReminderTargets

    /** Owner only: pushes a reminder; each member gets at most one a day from the owner. */
    suspend fun sendReminder(kametiId: String, message: String?, memberIds: List<String>?): ReminderResult
}

/** For builds without notifications: nothing to show, nothing to send. */
class UnavailableNotificationsRepository : NotificationsRepository {
    override suspend fun notifications(limit: Int): List<AppNotification> = emptyList()
    override suspend fun markRead(ids: List<String>?) {}
    override suspend fun registerDevice(token: String, platform: String) {}
    override suspend fun unregisterDevice(token: String) {}
    override suspend fun preferences(userId: String) = NotificationPreferences()
    override suspend fun updatePreferences(userId: String, preferences: NotificationPreferences) {}
    override suspend fun reminderTargets(kametiId: String) = ReminderTargets(dueDay = 10, members = emptyList())
    override suspend fun sendReminder(kametiId: String, message: String?, memberIds: List<String>?) =
        ReminderResult(sent = 0)
}
