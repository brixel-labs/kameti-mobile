package com.brixel.kameti.core

import kotlin.coroutines.cancellation.CancellationException

/**
 * Why a sign-in with Apple or Google didn't complete. (A cancelled sheet is
 * not a failure; sign-in returns `false` for it.)
 */
enum class SignInProblem {
    /** This build has no backend settings. */
    NotConfigured,

    /** The provider's client IDs or signing key don't match this build. */
    Misconfigured,

    /** The sign-in sheet was interrupted before it finished. */
    Interrupted,

    /** Sign-in can't be shown right now (no account on the device, no UI). */
    Unavailable,

    /** The provider answered but Kameti's backend refused the sign-in. */
    Rejected,
}

/**
 * Why a call failed. Repositories throw only this, never a raw Supabase or
 * network error, so screens can turn it into a message.
 */
sealed class Failure : Exception() {
    /**
     * A rule the backend enforced, for example `shares_must_sum_to_slot_amount`,
     * `not_kameti_owner` or `future_date`. [detail] is the English text the
     * backend sent; it is for logs, not for users.
     */
    data class Server(val code: String, val detail: String? = null) : Failure()

    /** No connection, or the request timed out. */
    data object Network : Failure() {
        private fun readResolve(): Any = Network
    }

    /** Sign-in problem or the session expired. */
    data class Auth(override val message: String) : Failure()

    /** A sign-in that failed, with a reason the screen can explain. */
    data class SignIn(val problem: SignInProblem, val detail: String? = null) : Failure()

    data class Unknown(val description: String) : Failure()
}

/** The result of [attempt]: the value, or the typed [Failure]. */
sealed interface Attempt<out T> {
    data class Success<T>(val value: T) : Attempt<T>
    data class Failed(val failure: Failure) : Attempt<Nothing>

    /** The value, or throws the [Failure]. */
    fun get(): T = when (this) {
        is Success -> value
        is Failed -> throw failure
    }

    fun getOrNull(): T? = (this as? Success)?.value
}

/**
 * Runs a call and keeps its [Failure] as a value, so an optional load that
 * fails never blocks the screen:
 *
 *     val notes = async { attempt { repo.notes(id) } }
 *     val shown = notes.await().getOrNull().orEmpty()
 *
 * The repositories only throw `Failure`; anything else (it shouldn't happen)
 * becomes `Unknown`. Cancellation is never swallowed.
 */
suspend fun <T> attempt(work: suspend () -> T): Attempt<T> =
    try {
        Attempt.Success(work())
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (failure: Failure) {
        Attempt.Failed(failure)
    } catch (other: Exception) {
        Attempt.Failed(Failure.Unknown(other.toString()))
    }
