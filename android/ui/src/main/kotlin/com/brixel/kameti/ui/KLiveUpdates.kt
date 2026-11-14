package com.brixel.kameti.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * The app-wide "something changed" signal. Live changes (and coming back to
 * the app) bump [revision]; screens watch it and reload quietly, without a
 * spinner. Bursts of changes are folded into one reload. Use it from the
 * main thread.
 */
class KLiveUpdates(private val scope: CoroutineScope) {
    /** Goes up once per batch of changes. */
    var revision by mutableIntStateOf(0)
        private set

    /** Kametis changed in the last batch; `null` means "anything may have". */
    var changedKametiIds by mutableStateOf<Set<String>?>(null)
        private set

    private var pending: MutableSet<String>? = mutableSetOf()
    private var flush: Job? = null

    /** A change arrived; a `null` [kametiId] means it can't be pinned to one kameti. */
    fun record(kametiId: String?) {
        if (kametiId != null) pending?.add(kametiId) else pending = null
        if (flush != null) return
        flush = scope.launch {
            delay(FOLD_MILLIS)
            flush = null
            publish()
        }
    }

    /** Back in the app: everything may have changed. */
    fun refreshAll() {
        pending = null
        publish()
    }

    /** Whether the last batch touches this kameti. */
    fun affects(kametiId: String): Boolean = changedKametiIds?.contains(kametiId) ?: true

    private fun publish() {
        flush?.cancel()
        flush = null
        changedKametiIds = pending?.toSet()
        pending = mutableSetOf()
        revision += 1
    }

    companion object {
        const val FOLD_MILLIS = 400L

        val shared: KLiveUpdates by lazy { KLiveUpdates(MainScope()) }
    }
}
