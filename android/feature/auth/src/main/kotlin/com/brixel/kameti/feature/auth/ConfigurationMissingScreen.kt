package com.brixel.kameti.feature.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.textSubtitle

/**
 * Shown when the app has no backend settings (no `KametiConfig.json`), so it
 * says why sign-in is off instead of pretending. [showsDeveloperHint] is for
 * debug builds.
 */
@Composable
fun ConfigurationMissingScreen(showsDeveloperHint: Boolean, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(KColors.background)
            .safeDrawingPadding()
            .padding(KSpace.xl),
        verticalArrangement = Arrangement.spacedBy(KSpace.md, alignment = androidx.compose.ui.Alignment.CenterVertically),
    ) {
        KIcon(KIcons.cloudProblem, tint = KColors.warning, size = 40.dp)
        KText(stringResource(R.string.auth_this_build_isnt_connected_to_the_kameti_service), KTextToken.title)
        if (showsDeveloperHint) {
            KText(
                stringResource(R.string.auth_android_developers_run_use_env),
                KTextToken.subtitle,
                color = KColors.textSubtitle,
            )
        }
    }
}
