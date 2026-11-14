package com.brixel.kameti.feature.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Seeded test accounts of the LOCAL Supabase (`kameti-backend/supabase/seed.sql`).
 * They never exist in kameti-prod, and their buttons only show in a dev
 * build that has a backend.
 */
enum class DevAccount(val email: String) {
    Owner("owner@kameti.test"),
    Member("member@kameti.test");

    companion object {
        internal const val PASSWORD = "kameti-dev-pass"
    }
}

/** The ways to sign in on Android. (iOS also has Apple.) */
enum class SignInProvider { Google }

data class SignInUiState(
    val busyProvider: SignInProvider? = null,
    val busyDevAccount: DevAccount? = null,
    val failure: Failure? = null,
) {
    val isBusy: Boolean get() = busyProvider != null || busyDevAccount != null
}

/**
 * Drives the sign-in screen. A cancelled sheet is not an error; every real
 * failure becomes a `Failure` the screen turns into a message.
 */
class SignInViewModel(
    private val auth: AuthRepository,
    val showsDevSignIn: Boolean = false,
) : ViewModel() {
    private val current = MutableStateFlow(SignInUiState())
    val state: StateFlow<SignInUiState> = current.asStateFlow()

    fun onSignIn(provider: SignInProvider) {
        viewModelScope.launch { signIn(provider) }
    }

    fun onSignIn(account: DevAccount) {
        viewModelScope.launch { signIn(account) }
    }

    /** On success the session store sees the new user and the root screen moves on. */
    suspend fun signIn(provider: SignInProvider) {
        if (current.value.isBusy) return
        current.update { it.copy(busyProvider = provider, failure = null) }
        try {
            when (provider) {
                SignInProvider.Google -> auth.signInWithGoogle()
            }
        } catch (failure: Failure) {
            current.update { it.copy(failure = failure) }
        } finally {
            current.update { it.copy(busyProvider = null) }
        }
    }

    suspend fun signIn(account: DevAccount) {
        if (current.value.isBusy) return
        current.update { it.copy(busyDevAccount = account, failure = null) }
        try {
            auth.signInWithPassword(account.email, DevAccount.PASSWORD)
        } catch (failure: Failure) {
            current.update { it.copy(failure = failure) }
        } finally {
            current.update { it.copy(busyDevAccount = null) }
        }
    }
}
