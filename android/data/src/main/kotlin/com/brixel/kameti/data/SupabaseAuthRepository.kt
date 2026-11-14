package com.brixel.kameti.data

import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.SignInProblem
import com.brixel.kameti.core.stringValue
import com.brixel.kameti.domain.AuthRepository
import com.brixel.kameti.domain.SignInMethod
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Apple
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.providers.builtin.IDToken
import io.github.jan.supabase.auth.status.SessionStatus
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.transform

/** What a social provider hands back after the user picks an account. */
data class ProviderCredential(
    val idToken: String,
    val accessToken: String? = null,
    /** The raw nonce whose hash the provider put in the token. */
    val nonce: String? = null,
)

/**
 * Shows a provider's sign-in sheet and returns its credential, `null` when
 * the user closes it. The app module implements this with Credential Manager,
 * so this module never links Google's libraries. Throws only `Failure`.
 */
fun interface ProviderCredentialSource {
    suspend fun credential(): ProviderCredential?
}

/**
 * Sign-in on Supabase Auth. Google is native (an ID token from [google]);
 * Apple has no native sheet on Android, so it opens Supabase's web sign-in in
 * a browser tab and the session arrives through the app's redirect link
 * (`KametiBackend.handleRedirect`).
 */
internal class SupabaseAuthRepository(
    private val client: SupabaseClient,
    private val google: ProviderCredentialSource? = null,
) : AuthRepository {
    override val currentUserId: String? get() = client.auth.currentUserOrNull()?.id

    override fun userIdChanges(): Flow<String?> = client.auth.sessionStatus.transform { status ->
        when (status) {
            is SessionStatus.Authenticated -> emit(status.session.user?.id)
            is SessionStatus.NotAuthenticated -> emit(null)
            // Offline with a saved session that couldn't be renewed: still
            // signed in, and the screens show their offline state.
            is SessionStatus.RefreshFailure -> emit(savedUserId())
            SessionStatus.Initializing -> Unit
        }
    }.distinctUntilChanged()

    private suspend fun savedUserId(): String? = try {
        client.auth.sessionManager.loadSession()?.user?.id
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (_: Exception) {
        null
    }

    override suspend fun signInWithGoogle(): Boolean {
        val source = google ?: throw Failure.SignIn(SignInProblem.Misconfigured, "no credential source for Google")
        val credential = source.credential() ?: return false
        signingIn {
            client.auth.signInWith(IDToken) {
                provider = Google
                idToken = credential.idToken
                accessToken = credential.accessToken
                nonce = credential.nonce
            }
        }
        return true
    }

    /** `true` once the browser tab is open; the session follows when the user finishes there. */
    override suspend fun signInWithApple(): Boolean {
        signingIn { client.auth.signInWith(Apple) }
        return true
    }

    override suspend fun signInWithPassword(email: String, password: String) {
        signingIn {
            client.auth.signInWith(Email) {
                this.email = email
                this.password = password
            }
        }
    }

    override suspend fun signOut() {
        call { client.auth.signOut() }
    }

    override suspend fun signInMethods(): List<SignInMethod> {
        val user = try {
            client.auth.retrieveUserForCurrentSession()
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (_: Exception) {
            return emptyList()
        }
        return user.identities.orEmpty().mapNotNull { identity ->
            val provider = SignInMethod.Provider.of(identity.provider) ?: return@mapNotNull null
            SignInMethod(provider, identity.identityData["email"]?.stringValue ?: user.email)
        }
    }

    private inline fun signingIn(body: () -> Unit) {
        try {
            body()
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Exception) {
            throw signInFailure(error)
        }
    }

    companion object {
        /** A refused sign-in says why; a network problem still says "offline". */
        internal fun signInFailure(error: Throwable): Failure = when (val failure = error.toFailure()) {
            is Failure.Auth -> Failure.SignIn(SignInProblem.Rejected, failure.message)
            is Failure.Network, is Failure.SignIn -> failure
            else -> Failure.SignIn(SignInProblem.Rejected, error.toString())
        }
    }
}
