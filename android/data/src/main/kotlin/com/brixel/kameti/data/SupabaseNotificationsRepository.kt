package com.brixel.kameti.data

import com.brixel.kameti.domain.AppNotification
import com.brixel.kameti.domain.NotificationPreferences
import com.brixel.kameti.domain.NotificationsRepository
import com.brixel.kameti.domain.ReminderResult
import com.brixel.kameti.domain.ReminderTargets
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.json.JsonNull

/**
 * Notifications through migration `notifications`: the inbox is a plain
 * select (RLS shows only mine); devices and read marks go through RPCs;
 * preferences are the `notify_*` columns of my profile.
 */
internal class SupabaseNotificationsRepository(private val client: SupabaseClient) : NotificationsRepository {
    override suspend fun notifications(limit: Int): List<AppNotification> = call {
        client.from("notifications").select(Columns.raw(AppNotification.COLUMNS)) {
            order("created_at", Order.DESCENDING)
            limit(limit.toLong())
        }.decodeList()
    }

    override suspend fun markRead(ids: List<String>?) {
        call { client.postgrest.rpc("mark_notifications_read", params("p_ids" to (ids?.let(::texts) ?: JsonNull))) }
    }

    override suspend fun registerDevice(token: String, platform: String) {
        call {
            client.postgrest.rpc("register_device", params("p_token" to text(token), "p_platform" to text(platform)))
        }
    }

    override suspend fun unregisterDevice(token: String) {
        call { client.postgrest.rpc("unregister_device", params("p_token" to text(token))) }
    }

    override suspend fun preferences(userId: String): NotificationPreferences = call {
        client.from("profiles").select(Columns.raw(NotificationPreferences.COLUMNS)) {
            filter { eq("id", userId) }
            single()
        }.decodeAs()
    }

    override suspend fun updatePreferences(userId: String, preferences: NotificationPreferences) {
        call {
            client.from("profiles").update({
                set("notify_reminders", preferences.notifyReminders)
                set("notify_payments", preferences.notifyPayments)
                set("notify_invites", preferences.notifyInvites)
                set("notify_changes", preferences.notifyChanges)
            }) { filter { eq("id", userId) } }
        }
    }

    override suspend fun reminderTargets(kametiId: String): ReminderTargets = call {
        client.postgrest.rpc("reminder_targets", params("p_kameti_id" to text(kametiId))).decodeAs()
    }

    override suspend fun sendReminder(kametiId: String, message: String?, memberIds: List<String>?): ReminderResult =
        call {
            client.postgrest.rpc(
                "send_reminder_broadcast",
                params(
                    "p_kameti_id" to text(kametiId),
                    "p_message" to opt(message),
                    "p_member_ids" to (memberIds?.let(::texts) ?: JsonNull),
                ),
            ).decodeAs()
        }
}
