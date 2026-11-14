package com.brixel.kameti.feature.shell

import androidx.compose.animation.Crossfade
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.feature.auth.SessionStore
import com.brixel.kameti.feature.auth.SignInScreen
import com.brixel.kameti.feature.auth.SignInViewModel
import com.brixel.kameti.navigation.AppRouter
import com.brixel.kameti.ui.KLoadingScreen

/** The root of the app: signed out shows sign-in, signed in shows the tabs. */
@Composable
fun RootScreen(
    session: SessionStore,
    router: AppRouter,
    signIn: SignInViewModel,
    dependencies: KametiDependencies,
    modifier: Modifier = Modifier,
    settings: ShellSettings = ShellSettings(),
) {
    val state by session.state.collectAsStateWithLifecycle()
    Crossfade(targetState = state, modifier = modifier, label = "session") { current ->
        when (current) {
            SessionStore.State.Loading -> KLoadingScreen()
            SessionStore.State.SignedOut -> SignInScreen(signIn)
            // A new user gets fresh screens and a clean tab state.
            is SessionStore.State.SignedIn -> key(current.userId) {
                MainTabs(router = router, userId = current.userId, dependencies = dependencies, settings = settings)
            }
        }
    }
}
