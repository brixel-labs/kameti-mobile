package com.brixel.kameti.testsupport

import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.AccountDeletionCheck
import com.brixel.kameti.domain.AccountRepository
import com.brixel.kameti.domain.AppNotification
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.NotificationPreferences
import com.brixel.kameti.domain.NotificationsRepository
import com.brixel.kameti.domain.ReminderResult
import com.brixel.kameti.domain.ReminderTargets
import java.time.Instant

/**
 * Account deletion in the demo, with the backend's rules: running kametis
 * the user owns block it; otherwise it "deletes" by signing out.
 */
class SampleAccountRepository(
    private val kametis: SampleKametiRepository,
    private val contacts: SampleContactStore,
    private val auth: FakeAuthRepository,
) : AccountRepository {
    override suspend fun deletionCheck(): AccountDeletionCheck {
        val all = kametis.listKametis()
        val mine = all.filter { it.ownerId == SampleData.USER_ID }
        fun ref(k: Kameti) = AccountDeletionCheck.KametiRef(k.id, k.name, k.status)
        val blocking = mine.filter { it.status == KametiStatus.Active }.map(::ref)
        val kept = setOf(KametiStatus.Completed, KametiStatus.Archived, KametiStatus.Cancelled)
        return AccountDeletionCheck(
            canDelete = blocking.isEmpty(), blockingKametis = blocking,
            draftsToDelete = mine.filter { it.status == KametiStatus.Draft }.map(::ref),
            ownedKametisKept = mine.filter { it.status in kept }.map(::ref),
            membershipsToUnlink = all.count { it.ownerId != SampleData.USER_ID },
            contactsToDelete = contacts.all.size,
        )
    }

    override suspend fun deleteAccount() {
        if (!deletionCheck().canDelete) throw Failure.Server("owner_has_active_kametis")
        auth.signOut()
    }
}

/**
 * The demo's Inbox updates: a few things that happened to the demo account,
 * kept in memory so "mark read" and preferences behave as on the backend.
 */
class SampleNotificationsRepository(now: Instant) : NotificationsRepository {
    private val lock = Any()
    private var items = listOf(
        AppNotification(
            "n1", "family", "payment", "payments", "Payment recorded",
            "Rs 2,50,000 from Ali Raza · Family kameti", createdAt = now.minusSeconds(HOUR),
        ),
        AppNotification(
            "n2", "office", "joined", "invites", "Omar Farooq joined", "Office kameti",
            createdAt = now.minusSeconds(5 * HOUR),
        ),
        AppNotification(
            "n3", "friends", "declined", "invites", "Zara declined the invite",
            "Friends kameti · you can invite them again", readAt = now.minusSeconds(20 * HOUR),
            createdAt = now.minusSeconds(26 * HOUR),
        ),
        AppNotification(
            "n4", "cousins", "payout_soon", "payments", "Your payout is next month",
            "Rs 6,00,000 in December · Cousins kameti", readAt = now.minusSeconds(40 * HOUR),
            createdAt = now.minusSeconds(50 * HOUR),
        ),
    )
    private var preferences = NotificationPreferences()
    private val tokens = mutableSetOf<String>()
    private val remindedToday = mutableSetOf<String>()

    override suspend fun notifications(limit: Int): List<AppNotification> =
        synchronized(lock) { items.sortedByDescending { it.createdAt }.take(limit) }

    override suspend fun markRead(ids: List<String>?): Unit = synchronized(lock) {
        items = items.map { item ->
            if ((ids == null || item.id in ids) && item.isUnread) item.markedRead(Instant.now()) else item
        }
    }

    override suspend fun registerDevice(token: String, platform: String): Unit = synchronized(lock) { tokens += token }
    override suspend fun unregisterDevice(token: String): Unit = synchronized(lock) { tokens -= token }
    override suspend fun preferences(userId: String): NotificationPreferences = synchronized(lock) { preferences }
    override suspend fun updatePreferences(userId: String, preferences: NotificationPreferences): Unit =
        synchronized(lock) { this.preferences = preferences }

    /** The family kameti's members who owe in the demo; Hira has no app. */
    override suspend fun reminderTargets(kametiId: String): ReminderTargets {
        val reminded = synchronized(lock) { remindedToday.toSet() }
        return ReminderTargets(
            dueDay = 10,
            members = listOf(
                ReminderTargets.Member("f4", "Omar Farooq", Money(250_000), hasApp = true, remindedToday = "f4" in reminded),
                ReminderTargets.Member("f6", "Faisal Iqbal", Money(250_000), hasApp = true, remindedToday = "f6" in reminded),
                ReminderTargets.Member("f5", "Hira Malik", Money(125_000), hasApp = false, phone = "0300 1234567"),
            ),
        )
    }

    /** One owner reminder per member per day, like send_reminder_broadcast. */
    override suspend fun sendReminder(kametiId: String, message: String?, memberIds: List<String>?): ReminderResult =
        synchronized(lock) {
            val names = mapOf("f4" to "Omar Farooq", "f6" to "Faisal Iqbal")
            val wanted = memberIds ?: listOf("f4", "f6")
            val skipped = wanted.filter { it in remindedToday }
            val sending = wanted.filterNot { it in remindedToday }
            if (sending.isEmpty()) {
                throw Failure.Server(if (skipped.isEmpty()) "nobody_to_remind" else "already_reminded_today")
            }
            remindedToday += sending
            ReminderResult(sent = sending.size, skipped = skipped.mapNotNull { names[it] })
        }
}
