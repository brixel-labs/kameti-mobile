package com.brixel.kameti.testsupport

import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.AuthRepository
import com.brixel.kameti.domain.Profile
import com.brixel.kameti.domain.ProfileRepository
import com.brixel.kameti.domain.SignInMethod
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

/**
 * An `AuthRepository` for tests and the demo. Set what each sign-in returns,
 * then read [calls] to see what the code under test did.
 */
class FakeAuthRepository(userId: String? = null) : AuthRepository {
    private val lock = Any()
    private val user = MutableStateFlow(userId)
    private var google: Attempt<Boolean> = Attempt.Success(true)
    private var password: Attempt<Unit> = Attempt.Success(Unit)
    private var signOut: Attempt<Unit> = Attempt.Success(Unit)
    private val called = mutableListOf<String>()

    // Configure

    fun setGoogle(result: Attempt<Boolean>) = synchronized(lock) { google = result }
    fun setPassword(result: Attempt<Unit>) = synchronized(lock) { password = result }
    fun setSignOut(result: Attempt<Unit>) = synchronized(lock) { signOut = result }

    /** Changes the signed-in user and tells every listener, as a real session would. */
    fun emit(userId: String?) {
        user.value = userId
    }

    /** Everything called so far, for example `["google", "signOut"]`. */
    val calls: List<String> get() = synchronized(lock) { called.toList() }

    // AuthRepository

    override val currentUserId: String? get() = user.value

    override fun userIdChanges(): Flow<String?> = user

    override suspend fun signInWithGoogle(): Boolean {
        val signedIn = synchronized(lock) { called += "google"; google }.get()
        if (signedIn) emit("google-user")
        return signedIn
    }

    override suspend fun signInWithPassword(email: String, password: String) {
        synchronized(lock) { called += "password:$email"; this.password }.get()
        emit("password-user")
    }

    /** The demo account was made with Apple on iOS (as in the iOS demo). */
    override suspend fun signInMethods(): List<SignInMethod> =
        if (currentUserId == null) emptyList() else listOf(SignInMethod(SignInMethod.Provider.Apple, "demo@kameti.test"))

    override suspend fun signOut() {
        synchronized(lock) { called += "signOut"; signOut }.get()
        emit(null)
    }
}

/** A `ProfileRepository` for tests and the demo. */
class FakeProfileRepository(
    result: Attempt<Profile> = Attempt.Success(Profile("u1", "Hassan")),
) : ProfileRepository {
    private val lock = Any()
    private var result = result
    private val loads = mutableListOf<String>()

    fun set(newResult: Attempt<Profile>) = synchronized(lock) { result = newResult }

    /** The user ids that were loaded. */
    val loadedUserIds: List<String> get() = synchronized(lock) { loads.toList() }

    override suspend fun myProfile(userId: String): Profile = synchronized(lock) {
        loads += userId
        result
    }.get()

    /** Like the backend: 1–80 characters after trimming. */
    override suspend fun updateDisplayName(userId: String, name: String): Profile {
        val trimmed = name.trim()
        if (trimmed.length !in 1..80) throw Failure.Server("invalid_name")
        return synchronized(lock) {
            val updated = result.get().copy(displayName = trimmed)
            result = Attempt.Success(updated)
            updated
        }
    }
}
