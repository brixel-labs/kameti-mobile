package com.brixel.kameti.feature.shell

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.attempt
import com.brixel.kameti.domain.AccountDeletionCheck
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Profile
import com.brixel.kameti.domain.ProfileSnapshot
import com.brixel.kameti.domain.SignInMethod
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class ProfileUiState(
    val profile: Profile? = null,
    val runningCount: Int = 0,
    val memberCount: Int = 0,
    /** Completed and cancelled kametis. Archived ones live on Home (Past → Archived), not here. */
    val pastKametis: List<Kameti> = emptyList(),
    /** The owner's saved people, by name. */
    val people: List<Contact> = emptyList(),
    val signInMethods: List<SignInMethod> = emptyList(),
    val failure: Failure? = null,
    val isLoading: Boolean = false,
) {
    val pastCount: Int get() = pastKametis.size
    val peopleCount: Int get() = people.size

    /** The name looks made up by sign-up (no name from Apple or Google). */
    val nameIsPlaceholder: Boolean
        get() {
            val name = profile?.displayName?.trim().orEmpty()
            if (name.isEmpty() || name == "Kameti user") return true
            return signInMethods.any { it.email?.substringBefore("@") == name }
        }
}

/**
 * The signed-in user's profile (name and how many kametis they run or are
 * in) and sign-out.
 */
class ProfileViewModel(val userId: String, val dependencies: KametiDependencies) : ViewModel() {
    private val cache = dependencies.profileCache
    private val current = MutableStateFlow(ProfileUiState())
    val state: StateFlow<ProfileUiState> = current.asStateFlow()

    init {
        apply(cache.load(userId))
    }

    fun onRefresh() {
        viewModelScope.launch { refresh() }
    }

    /**
     * Shows what's saved on the phone. Calls the server only when nothing is
     * saved yet (first sign-in on this phone); pull to refresh fetches fresh.
     */
    suspend fun load() {
        val cached = cache.load(userId)
        apply(cached)
        if (cached.profile == null || cached.kametis == null || cached.people == null) refresh()
    }

    /** Fetches everything from the server and saves it on the phone. */
    suspend fun refresh() {
        if (current.value.isLoading) return
        current.update { it.copy(isLoading = true, failure = null) }
        try {
            val me = dependencies.profiles.myProfile(userId)
            val all = dependencies.kametis.listKametis()
            val contacts = attempt { dependencies.contacts.contacts() }.getOrNull() ?: current.value.people
            val methods = dependencies.auth.signInMethods()
            cache.update(userId) { it.copy(profile = me, kametis = all, people = contacts) }
            cache.setSignInMethods(userId, methods)
            apply(cache.load(userId))
        } catch (failure: Failure) {
            current.update { it.copy(failure = failure) }
        } finally {
            current.update { it.copy(isLoading = false) }
        }
    }

    private fun apply(snapshot: ProfileSnapshot) {
        current.update { state ->
            var next = state
            snapshot.profile?.let { next = next.copy(profile = it) }
            snapshot.kametis?.let { all ->
                val running = all.count { it.isOwnedBy(userId) }
                next = next.copy(
                    runningCount = running,
                    memberCount = all.size - running,
                    pastKametis = all.filter { it.status == KametiStatus.Completed || it.status == KametiStatus.Cancelled },
                )
            }
            snapshot.people?.let { contacts -> next = next.copy(people = contacts.sortedBy { it.name.lowercase() }) }
            snapshot.signInMethods?.let { next = next.copy(signInMethods = it) }
            next
        }
    }

    /** True when this Apple or Google sign-in hasn't been asked for a name yet. */
    val needsNamePrompt: Boolean
        get() {
            val state = current.value
            if (state.profile == null || cache.load(userId).namePrompted == true) return false
            return state.signInMethods.any { it.provider == SignInMethod.Provider.Apple || it.provider == SignInMethod.Provider.Google }
        }

    fun markNamePrompted() = cache.update(userId) { it.copy(namePrompted = true) }

    /** Saves the name other people see. Returns the failure to show, or `null`. */
    suspend fun updateName(name: String): Failure? {
        try {
            val saved = dependencies.profiles.updateDisplayName(userId, name)
            current.update { it.copy(profile = saved) }
            cache.update(userId) { it.copy(profile = saved) }
        } catch (failure: Failure) {
            return failure
        }
        return null
    }

    /** What deleting the account would do (it may be blocked). */
    suspend fun deletionCheck(): Attempt<AccountDeletionCheck> = attempt { dependencies.account.deletionCheck() }

    /** Archives a kameti that blocks account deletion (§6.11, D5). */
    suspend fun archiveKameti(id: String): Failure? {
        try {
            dependencies.kametis.archiveKameti(id)
        } catch (failure: Failure) {
            return failure
        }
        refresh()
        return null
    }

    /** Deletes the account, then signs out; the root screen moves on. */
    suspend fun deleteAccount(): Failure? {
        try {
            dependencies.account.deleteAccount()
        } catch (failure: Failure) {
            return failure
        }
        // The sign-in is gone on the server; clear it on the phone too.
        cache.clear(userId)
        attempt { dependencies.auth.signOut() }
        return null
    }

    /** The session store notices the signed-out state and the root screen moves on. */
    suspend fun signOut() {
        try {
            dependencies.auth.signOut()
            cache.clear(userId)
        } catch (failure: Failure) {
            current.update { it.copy(failure = failure) }
        }
    }
}
