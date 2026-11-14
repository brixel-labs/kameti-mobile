package com.brixel.kameti

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.lifecycle.viewmodel.compose.viewModel
import com.brixel.kameti.feature.auth.ConfigurationMissingScreen
import com.brixel.kameti.feature.shell.RootScreen
import com.brixel.kameti.ui.KAppearance
import com.brixel.kameti.ui.KTheme

class MainActivity : ComponentActivity() {
    private val container: AppContainer? get() = (application as KametiApplication).container

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        // Not after a rotation: the link was handled the first time.
        if (savedInstanceState == null) container?.handle(intent)
        val showsGallery = BuildConfig.DEBUG && intent.getBooleanExtra(EXTRA_GALLERY, false)
        setContent {
            val container = container
            var appearance by rememberSaveable {
                mutableStateOf(KAppearance.of(container?.storage?.read(KAppearance.STORAGE_KEY)))
            }
            KTheme(dark = appearance.isDark(isSystemInDarkTheme())) {
                when {
                    showsGallery -> GalleryScreen(appearance, onAppearance = { appearance = it })
                    container == null -> ConfigurationMissingScreen(showsDeveloperHint = BuildConfig.DEBUG)
                    else -> RootScreen(
                        session = container.session,
                        router = container.router,
                        signIn = viewModel { container.makeSignInViewModel() },
                        dependencies = container.dependencies,
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        container?.handle(intent)
    }

    companion object {
        /**
         * Debug builds: opens the design-system gallery instead of the app.
         * `adb shell am start -n com.brixel.kameti/.MainActivity --ez gallery true`
         */
        const val EXTRA_GALLERY = "gallery"
    }
}
