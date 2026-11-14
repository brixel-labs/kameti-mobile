package com.brixel.kameti

import android.app.Activity
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.SignInProblem
import com.brixel.kameti.data.ProviderCredential
import com.brixel.kameti.data.ProviderCredentialSource
import com.brixel.kameti.data.SignInNonce
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException

/**
 * Google's account sheet (Credential Manager), then the ID token for
 * Supabase. [serverClientId] is the **web** OAuth client ID: Supabase checks
 * the token against it. Google also needs an Android OAuth client registered
 * with this app's package name and signing fingerprint.
 */
class GoogleCredentialSource(
    private val serverClientId: String,
    private val currentActivity: () -> Activity?,
) : ProviderCredentialSource {
    override suspend fun credential(): ProviderCredential? {
        val activity = currentActivity()
            ?: throw Failure.SignIn(SignInProblem.Unavailable, "no activity to show Google sign-in from")
        // Google puts the hash in the token; Supabase checks it against the raw value.
        val nonce = SignInNonce.make()
        val option = GetSignInWithGoogleOption.Builder(serverClientId).setNonce(nonce.hashed).build()
        val request = GetCredentialRequest.Builder().addCredentialOption(option).build()
        val credential = try {
            CredentialManager.create(activity).getCredential(activity, request).credential
        } catch (_: GetCredentialCancellationException) {
            return null
        } catch (error: NoCredentialException) {
            throw Failure.SignIn(SignInProblem.Unavailable, error.toString())
        } catch (error: GetCredentialException) {
            throw Failure.SignIn(SignInProblem.Misconfigured, error.toString())
        }
        if (credential !is CustomCredential || credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
            throw Failure.SignIn(SignInProblem.Rejected, "Google returned ${credential.type}, not an ID token")
        }
        val token = try {
            GoogleIdTokenCredential.createFrom(credential.data).idToken
        } catch (error: GoogleIdTokenParsingException) {
            throw Failure.SignIn(SignInProblem.Rejected, error.toString())
        }
        return ProviderCredential(idToken = token, nonce = nonce.raw)
    }
}
