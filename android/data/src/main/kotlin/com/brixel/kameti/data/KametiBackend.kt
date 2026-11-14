package com.brixel.kameti.data

import android.content.Intent
import com.brixel.kameti.core.KametiClock
import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KeyValueStorage
import com.brixel.kameti.domain.ProfileCache
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.ExternalAuthAction
import io.github.jan.supabase.auth.FlowType
import io.github.jan.supabase.auth.handleDeeplinks
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.serializer.KotlinXSerializer

/**
 * The real backend: one Supabase client and every repository on it. Rows
 * decode with `KametiJson` (snake_case keys, date-only columns, ISO
 * timestamps).
 */
class KametiBackend private constructor(
    private val client: SupabaseClient,
    val dependencies: KametiDependencies,
) {
    /**
     * Finishes a browser sign-in (Apple): call with every intent the activity
     * is opened with. Intents that aren't the sign-in redirect are ignored.
     */
    fun handleRedirect(intent: Intent) {
        // A cancelled or refused web sign-in simply leaves the user signed out.
        client.handleDeeplinks(intent)
    }

    companion object {
        /** The redirect link of a browser sign-in: `com.brixel.kameti://login-callback`. */
        const val REDIRECT_SCHEME = "com.brixel.kameti"
        const val REDIRECT_HOST = "login-callback"

        /**
         * The real dependencies. The Google sign-in sheet is injected so this
         * module never links its SDK.
         */
        fun create(
            url: String,
            publishableKey: String,
            google: ProviderCredentialSource? = null,
            profileStorage: KeyValueStorage? = null,
            clock: KametiClock = KametiClock(),
        ): KametiBackend {
            val client = createSupabaseClient(url, publishableKey) {
                // The scheme is dropped from the URL; a local Supabase is plain http.
                useHTTPS = !url.startsWith("http://")
                defaultSerializer = KotlinXSerializer(KametiJson.json)
                install(Postgrest)
                install(Functions)
                install(Realtime)
                install(Auth) {
                    flowType = FlowType.PKCE
                    scheme = REDIRECT_SCHEME
                    host = REDIRECT_HOST
                    defaultExternalAuthAction = ExternalAuthAction.CustomTabs()
                }
            }
            return KametiBackend(client, dependencies(client, google, profileStorage, clock))
        }

        internal fun dependencies(
            client: SupabaseClient,
            google: ProviderCredentialSource? = null,
            profileStorage: KeyValueStorage? = null,
            clock: KametiClock = KametiClock(),
        ) = KametiDependencies(
            kametis = SupabaseKametiRepository(client),
            ledger = SupabaseLedgerRepository(client),
            payments = SupabasePaymentsRepository(client),
            invites = SupabaseInvitesRepository(client),
            audit = SupabaseAuditRepository(client),
            profiles = SupabaseProfileRepository(client),
            contacts = SupabaseContactsRepository(client),
            auth = SupabaseAuthRepository(client, google),
            notes = SupabaseNotesRepository(client),
            account = SupabaseAccountRepository(client),
            notifications = SupabaseNotificationsRepository(client),
            live = SupabaseLiveUpdates(client),
            clock = clock,
            profileCache = if (profileStorage != null) ProfileCache(profileStorage, clock) else ProfileCache(clock = clock),
        )
    }
}
