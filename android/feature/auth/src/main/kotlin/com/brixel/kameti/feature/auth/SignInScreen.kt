package com.brixel.kameti.feature.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.core.Failure
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KButtonStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KGoogleLogo
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.userMessage

/**
 * Sign-in screen (board AF-Sign-In): Continue with Google, plus two dev
 * buttons in a dev build. Android has no Sign in with Apple (the owner's
 * decision): an account made with Apple on iOS can't sign in here.
 */
@Composable
fun SignInScreen(model: SignInViewModel, modifier: Modifier = Modifier) {
    val state by model.state.collectAsStateWithLifecycle()
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(KColors.background)
            .safeDrawingPadding()
            .padding(horizontal = KSpace.xl)
            .padding(bottom = KSpace.xl),
        verticalArrangement = Arrangement.spacedBy(KSpace.lg),
    ) {
        Spacer(Modifier.weight(1f))
        Box(
            Modifier.size(72.dp).background(KColors.brand, RoundedCornerShape(KRadius.xl * 0.8f)),
            contentAlignment = Alignment.Center,
        ) {
            KIcon(KIcons.peopleThreeFilled, tint = KColors.textOnBrand, size = 36.dp)
        }
        KText(stringResource(R.string.auth_run_your_kameti_track_every_turn), KTextToken.displayLg)
        KText(
            stringResource(R.string.auth_record_who_paid_see_whose_turn_is_next),
            KTextToken.body,
            color = KColors.textSecondary,
        )
        Spacer(Modifier.weight(1f))
        state.failure?.let { FailureBanner(it) }
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
            KButton(
                title = stringResource(R.string.auth_continue_with_google),
                onClick = { model.onSignIn(SignInProvider.Google) },
                style = KButtonStyle.Secondary,
                leading = { KGoogleLogo() },
                enabled = !state.isBusy || state.busyProvider == SignInProvider.Google,
                isLoading = state.busyProvider == SignInProvider.Google,
            )
            if (model.showsDevSignIn) {
                Box(
                    Modifier
                        .padding(vertical = KSpace.xs)
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(KColors.divider),
                )
                for (account in DevAccount.entries) {
                    KButton(
                        title = stringResource(
                            if (account == DevAccount.Owner) R.string.auth_dev_sign_in_as_owner
                            else R.string.auth_dev_sign_in_as_member,
                        ),
                        onClick = { model.onSignIn(account) },
                        style = KButtonStyle.Secondary,
                        enabled = !state.isBusy || state.busyDevAccount == account,
                        isLoading = state.busyDevAccount == account,
                    )
                }
            }
        }
    }
}

/** The reason a sign-in failed, in plain words. Raw causes never reach the screen. */
@Composable
private fun FailureBanner(failure: Failure) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(KColors.negativeSubtle, RoundedCornerShape(KRadius.input))
            .padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        KIcon(KIcons.warning, tint = KColors.negative, size = 18.dp)
        KText(failure.userMessage(), KTextToken.bodySm, color = KColors.negative)
    }
}
