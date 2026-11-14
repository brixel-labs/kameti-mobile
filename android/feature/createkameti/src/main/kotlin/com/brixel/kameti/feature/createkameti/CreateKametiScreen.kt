package com.brixel.kameti.feature.createkameti

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KIconButton
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageSheet
import com.brixel.kameti.ui.KSheetMessage
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KSpinner
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.kDismissesKeyboard
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.textSubtitle
import com.brixel.kameti.ui.userMessage

/**
 * The create-kameti wizard, six steps (boards AC-1 to AC-6, FR-10 to FR-12).
 * Owner only: whoever creates the kameti owns it. The draft lives on the
 * server from step 1, so closing the wizard keeps it.
 *
 * With [draftId] it reopens that saved draft at its first unfinished step.
 * The system Back button steps back through the wizard, then closes it.
 */
@Composable
fun CreateKametiScreen(
    model: CreateWizardViewModel,
    onStarted: (String) -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    draftId: String? = null,
) {
    val state by model.state.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) {
        model.loadOwner()
        if (draftId != null && model.state.value.kametiId == null) model.resume(draftId)
    }
    BackHandler(enabled = !state.isAtStart) { model.back() }

    Column(
        modifier.fillMaxSize().background(KColors.background).navigationBarsPadding().imePadding().kDismissesKeyboard(),
    ) {
        Row(Modifier.fillMaxWidth().height(56.dp).padding(horizontal = KSpace.xs), verticalAlignment = Alignment.CenterVertically) {
            if (state.isAtStart) {
                KIconButton(KIcons.close, stringResource(R.string.create_close), onClose, tint = KColors.textPrimary)
            } else {
                KIconButton(KIcons.chevronLeft, stringResource(R.string.create_back), { model.back() }, tint = KColors.textPrimary)
            }
            KText(
                stringResource(if (state.isResumed) R.string.create_finish_setting_up else R.string.create_new_kameti),
                KTextToken.title, modifier = Modifier.weight(1f), maxLines = 1,
            )
            // A reopened draft starts mid-way, so it can be closed from any
            // step; everything is already saved on the server.
            if (state.isResumed && !state.isAtStart) {
                KIconButton(KIcons.close, stringResource(R.string.create_close), onClose, tint = KColors.textPrimary)
            }
        }
        Column(
            Modifier.fillMaxWidth().padding(horizontal = KSpace.xl).padding(top = KSpace.xs),
            horizontalAlignment = Alignment.End,
            verticalArrangement = Arrangement.spacedBy(KSpace.xs),
        ) {
            WizardProgress(state.step)
            KText(
                stringResource(R.string.create_step_n_of_n, state.step.ordinal + 1, WizardStep.entries.size),
                KTextToken.subtitle.copy(tabular = true), color = KColors.textSubtitle,
            )
        }
        if (state.isLoadingDraft) {
            Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) { KSpinner() }
        } else {
            AnimatedContent(
                targetState = state.step,
                modifier = Modifier.weight(1f).clipToBounds(),
                transitionSpec = {
                    // Forward slides in from the right, back from the left.
                    val direction = if (targetState.ordinal >= initialState.ordinal) 1 else -1
                    slideInHorizontally(tween(350)) { it * direction } togetherWith
                        slideOutHorizontally(tween(350)) { -it * direction }
                },
                label = "step",
            ) { step ->
                when (step) {
                    WizardStep.Basics -> BasicsStep(state, model)
                    WizardStep.Dates -> DatesStep(state, model)
                    WizardStep.Members -> MembersStep(state, model)
                    WizardStep.Slots -> SlotsStep(state, model)
                    WizardStep.Order -> OrderStep(state, model)
                    WizardStep.Review -> ReviewStep(state, model, onStart = onStarted, onSaveDraft = onClose)
                }
            }
        }
    }

    KMessageSheet(
        state.failure?.let {
            KSheetMessage(stringResource(R.string.create_something_went_wrong), it.userMessage(), KSheetMessage.Tone.Error)
        },
        onDismiss = { model.clearFailure() },
    )
}
