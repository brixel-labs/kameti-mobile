package com.brixel.kameti

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.core.content.edit
import com.brixel.kameti.data.KametiBackend
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KeyValueStorage
import com.brixel.kameti.domain.ProfileCache
import com.brixel.kameti.feature.auth.SessionStore
import com.brixel.kameti.feature.auth.SignInViewModel
import com.brixel.kameti.navigation.AppRouter
import com.brixel.kameti.testsupport.SampleData
import kotlinx.coroutines.MainScope

/**
 * The composition root: the one place that turns the config into the real
 * (Supabase) dependencies and hands them to the features. It lives as long
 * as the app process, so a rotation keeps the session and the tab stacks.
 */
class AppContainer(config: AppConfig, context: Context, currentActivity: () -> Activity?) {
    val storage: KeyValueStorage = PreferencesStorage(context)
    val router = AppRouter()
    val dependencies: KametiDependencies
    val session: SessionStore
    private val backend: KametiBackend?
    private val showsDevSignIn = config.isDev()

    init {
        if (config.isDemo()) {
            // Sample kametis, no backend: see every screen without data.
            backend = null
            val sample = SampleData.dependencies()
            dependencies = sample.copy(profileCache = ProfileCache(storage, sample.clock))
        } else {
            val google = config.googleWebClientId?.let { GoogleCredentialSource(serverClientId = it, currentActivity) }
            backend = KametiBackend.create(
                url = config.backendUrl(),
                publishableKey = config.supabasePublishableKey,
                google = google,
                profileStorage = storage,
            )
            dependencies = backend.dependencies
        }
        session = SessionStore(dependencies.auth, MainScope()).also { it.start() }
    }

    fun makeSignInViewModel() = SignInViewModel(dependencies.auth, showsDevSignIn)

    /**
     * An intent the activity was opened with: the end of a browser sign-in
     * (Apple), or an invite link.
     */
    fun handle(intent: Intent) {
        backend?.handleRedirect(intent)
        intent.dataString?.let(router::open)
    }
}

/** Small on-device settings in SharedPreferences. */
class PreferencesStorage(context: Context) : KeyValueStorage {
    private val preferences = context.applicationContext.getSharedPreferences("kameti", Context.MODE_PRIVATE)

    override fun read(key: String): String? = preferences.getString(key, null)
    override fun write(key: String, value: String) = preferences.edit { putString(key, value) }
    override fun remove(key: String) = preferences.edit { remove(key) }
}
