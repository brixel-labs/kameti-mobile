package com.brixel.kameti.feature.shell

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.attempt
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.Profile
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KAvatarSize
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KButtonStyle
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KSheetMessage
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTopBar
import com.brixel.kameti.ui.helpMessage
import com.brixel.kameti.ui.userMessage

// Stand-ins until each screen is ported (see docs/ROADMAP.md, "Android port").
// Profile is real enough to check who is signed in and to sign out.

/** A screen that isn't ported yet. With [onBack] it is a pushed screen. */
@Composable
internal fun ComingNext(title: String, onBack: (() -> Unit)? = null) {
    Column(Modifier.fillMaxSize()) {
        if (onBack != null) KTopBar(title, onBack) else TabTitle(title)
        KMessageCard(
            title = stringResource(R.string.shell_this_screen_is_coming_next),
            modifier = Modifier.padding(horizontal = KSpace.gutter),
            icon = KIcons.hourglass,
        )
    }
}

@Composable
private fun TabTitle(title: String) {
    KText(
        title,
        KTextToken.display,
        modifier = Modifier.padding(start = KSpace.gutter, end = KSpace.gutter, top = KSpace.lg, bottom = KSpace.md),
    )
}

/** Profile for now: who is signed in, and Sign out. */
@Composable
internal fun ProfileComingNext(userId: String, dependencies: KametiDependencies) {
    var profile by remember { mutableStateOf<Profile?>(null) }
    var confirmingSignOut by remember { mutableStateOf(false) }
    val context = LocalContext.current
    LaunchedEffect(userId) { profile = attempt { dependencies.profiles.myProfile(userId) }.getOrNull() }

    Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
        TabTitle(stringResource(R.string.shell_profile))
        Column(
            Modifier.padding(horizontal = KSpace.gutter),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            profile?.let { shown ->
                KCard {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        KAvatar(shown.displayName, colorIndex = 0, size = KAvatarSize.Large)
                        KText(shown.displayName, KTextToken.title)
                    }
                }
            }
            KMessageCard(title = stringResource(R.string.shell_this_screen_is_coming_next), icon = KIcons.hourglass)
            KButton(
                title = stringResource(R.string.shell_sign_out),
                onClick = { confirmingSignOut = true },
                style = KButtonStyle.Secondary,
                icon = KIcons.signOut,
            )
        }
    }

    if (confirmingSignOut) {
        KConfirmSheet(
            title = stringResource(R.string.shell_sign_out_of_kameti),
            confirmTitle = stringResource(R.string.shell_sign_out),
            onDismiss = { confirmingSignOut = false },
            onConfirm = {
                when (val result = attempt { dependencies.auth.signOut() }) {
                    is Attempt.Success -> KConfirmOutcome.Dismiss
                    is Attempt.Failed -> KConfirmOutcome.Result(
                        KSheetMessage(
                            result.failure.userMessage(context),
                            result.failure.helpMessage(context),
                            KSheetMessage.Tone.Error,
                        ),
                    )
                }
            },
            message = stringResource(R.string.shell_youll_need_to_sign_in_again_to_see),
        )
    }
}
