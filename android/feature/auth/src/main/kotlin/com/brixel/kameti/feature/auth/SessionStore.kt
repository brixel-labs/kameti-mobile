package com.brixel.kameti.feature.auth

import com.brixel.kameti.domain.AuthRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Who is signed in. Follows the auth repository's stream, so a sign-in, a
 * sign-out and an expired session all end up here.
 */
class SessionStore(private val auth: AuthRepository, private val scope: CoroutineScope) {
    sealed interface State {
        /** Waiting for the first answer from the auth repository. */
        data object Loading : State
        data object SignedOut : State
        data class SignedIn(val userId: String) : State
    }

    private val current = MutableStateFlow<State>(State.Loading)
    val state: StateFlow<State> = current.asStateFlow()

    private var listener: Job? = null

    /** Starts following the session. Safe to call more than once. */
    fun start() {
        if (listener != null) return
        listener = scope.launch {
            auth.userIdChanges().collect { userId ->
                current.value = if (userId != null) State.SignedIn(userId) else State.SignedOut
            }
        }
    }

    fun stop() {
        listener?.cancel()
        listener = null
    }
}
