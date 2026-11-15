package com.brixel.kameti.feature.createkameti

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.clickable
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
import androidx.compose.runtime.setValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KIconButton
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KNavButton
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
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay

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
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var showingMenu by remember { mutableStateOf(false) }
    var confirmingDelete by remember { mutableStateOf(false) }

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
                KNavButton(KIcons.close, stringResource(R.string.create_close), onClose)
            } else {
                KNavButton(KIcons.chevronLeft, stringResource(R.string.create_back), { model.back() })
            }
            KText(
                stringResource(if (state.isResumed) R.string.create_finish_setting_up else R.string.create_new_kameti),
                KTextToken.title, modifier = Modifier.weight(1f), maxLines = 1,
            )
            // Once the draft exists on the server it can be deleted from the wizard (nothing is recorded in one).
            if (state.kametiId != null) {
                KIconButton(KIcons.more, stringResource(R.string.create_more), { showingMenu = true }, tint = KColors.textPrimary)
            }
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

    if (showingMenu) {
        KBottomSheet(stringResource(R.string.create_new_kameti), onDismiss = { showingMenu = false }) { close ->
            Row(
                Modifier.fillMaxWidth().padding(horizontal = KSpace.xl).padding(bottom = KSpace.xl).heightIn(min = 52.dp)
                    .clickable(role = Role.Button) {
                        close()
                        confirmingDelete = true
                    },
                horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                KIcon(KIcons.trash, tint = KColors.negative)
                KText(stringResource(R.string.create_delete_draft), KTextToken.body, color = KColors.negative)
            }
        }
    }
    if (confirmingDelete) {
        KConfirmSheet(
            title = stringResource(R.string.create_delete_this_draft),
            confirmTitle = stringResource(R.string.create_delete_draft),
            onDismiss = { confirmingDelete = false },
            onConfirm = {
                val failure = model.deleteDraft()
                if (failure != null) {
                    KConfirmOutcome.Result(
                        KSheetMessage(
                            context.getString(R.string.create_couldnt_delete_this_draft), failure.userMessage(context), KSheetMessage.Tone.Error,
                        ),
                    )
                } else {
                    // Let the sheet close, then leave the wizard (Home reloads and the draft is gone).
                    scope.launch {
                        delay(450)
                        onClose()
                    }
                    KConfirmOutcome.Dismiss
                }
            },
            message = stringResource(R.string.create_the_setup_the_people_you_added_and_any),
            isDestructive = true,
        )
    }

    KMessageSheet(
        state.failure?.let {
            KSheetMessage(stringResource(R.string.create_something_went_wrong), it.userMessage(), KSheetMessage.Tone.Error)
        },
        onDismiss = { model.clearFailure() },
    )
}
