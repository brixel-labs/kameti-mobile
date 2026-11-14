package com.brixel.kameti.data

import com.brixel.kameti.core.stringValue
import com.brixel.kameti.domain.LiveChange
import com.brixel.kameti.domain.LiveUpdatesRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.realtime.HasOldRecord
import io.github.jan.supabase.realtime.HasRecord
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.RealtimeChannel
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.realtime
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Supabase Realtime (migration `realtime`): one channel listening to every
 * table the app shows. The server applies RLS per listener, so only rows the
 * user may read arrive. A change only says which kameti moved; screens reload.
 */
internal class SupabaseLiveUpdates(private val client: SupabaseClient) : LiveUpdatesRepository {
    private val lock = Mutex()
    private var channel: RealtimeChannel? = null
    private var listeners: CoroutineScope? = null

    override suspend fun start(onChange: (LiveChange) -> Unit) = lock.withLock {
        if (channel != null) return@withLock
        val channel = client.channel("kameti-live")
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        for (table in TABLES) {
            channel.postgresChangeFlow<PostgresAction>(schema = "public") { this.table = table }
                .onEach { onChange(LiveChange(table, kametiId(it, table))) }
                .launchIn(scope)
        }
        this.channel = channel
        listeners = scope
        try {
            channel.subscribe()
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (_: Exception) {
            // Offline or not allowed: screens still refresh on open and on pull.
            close()
        }
    }

    override suspend fun stop() = lock.withLock { close() }

    private suspend fun close() {
        listeners?.cancel()
        listeners = null
        val open = channel ?: return
        channel = null
        try {
            client.realtime.removeChannel(open)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (_: Exception) {
            // Already gone.
        }
    }

    companion object {
        private val TABLES = listOf("kametis", "members", "slots", "shares", "payments", "payouts", "notifications")

        private fun kametiId(action: PostgresAction, table: String): String? {
            val row = (action as? HasRecord)?.record ?: (action as? HasOldRecord)?.oldRecord ?: return null
            return row[if (table == "kametis") "id" else "kameti_id"]?.stringValue
        }
    }
}
