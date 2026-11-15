package com.brixel.kameti.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.ModalBottomSheetProperties
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import kotlinx.coroutines.launch

/**
 * The shared bottom sheet: grabber, a title with a close button and the
 * content. Show it while something is open:
 *
 *     if (isOpen) KBottomSheet(title, onDismiss = { isOpen = false }) { close -> ... }
 *
 * [content] gets a `close` function that slides the sheet away and then calls
 * [onDismiss]; use it instead of flipping the flag, so the sheet animates out.
 * While [dismissDisabled] (something is saving) it can't be swiped, tapped or
 * backed away.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun KBottomSheet(
    title: String,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
    /** Opens at full height straight away (forms); otherwise it fits its content, up to half the screen first. */
    expanded: Boolean = false,
    dismissDisabled: Boolean = false,
    content: @Composable ColumnScope.(close: () -> Unit) -> Unit,
) {
    val locked by rememberUpdatedState(dismissDisabled)
    // `close` is often called right after the work that kept the sheet locked finished, before the
    // next recomposition has unlocked it: closing on purpose must never be vetoed by the stale lock.
    var closing by remember { mutableStateOf(false) }
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = expanded, confirmValueChange = { closing || !locked })
    val scope = rememberCoroutineScope()
    val close: () -> Unit = {
        closing = true
        scope.launch { state.hide() }.invokeOnCompletion { if (!state.isVisible) onDismiss() }
    }
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        modifier = modifier,
        sheetState = state,
        shape = RoundedCornerShape(topStart = KRadius.xl, topEnd = KRadius.xl),
        containerColor = KColors.background,
        contentColor = KColors.textPrimary,
        scrimColor = KColors.overlay,
        dragHandle = {
            Box(Modifier.padding(top = 10.dp).size(width = 40.dp, height = 5.dp).background(KColors.borderStrong, CircleShape))
        },
        properties = ModalBottomSheetProperties(shouldDismissOnBackPress = !dismissDisabled),
    ) {
        // A full-page sheet has a fixed height that leaves a gap under the status bar from its first frame
        // (rounded top and the screen dimmed above), so it neither jumps to edge-to-edge nor covers the status bar.
        Column(
            Modifier.fillMaxWidth()
                .then(if (expanded) Modifier.fillMaxHeight(FULL_PAGE_SHEET_HEIGHT) else Modifier)
                .navigationBarsPadding().kDismissesKeyboard(),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = KSpace.xl).padding(top = KSpace.sm, bottom = KSpace.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                KText(title, KTextToken.title, modifier = Modifier.weight(1f))
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        // While something is saving, the sheet can't be closed.
                        .alpha(if (dismissDisabled) 0.35f else 1f)
                        .clip(CircleShape)
                        .background(KColors.surfaceSunken)
                        .clickable(enabled = !dismissDisabled, role = Role.Button, onClick = close),
                    contentAlignment = Alignment.Center,
                ) {
                    KIcon(KIcons.close, size = 18.dp, label = stringResource(R.string.ui_close))
                }
            }
            content(close)
        }
    }
}

/** How much of the screen's height a full-page sheet takes; the rest is the gap above it. */
private const val FULL_PAGE_SHEET_HEIGHT = 0.93f

/** A title and message for a result or a notice sheet. */
data class KSheetMessage(val title: String, val message: String, val tone: Tone = Tone.Info) {
    enum class Tone { Success, Info, Warning, Error }

    internal val icon: ImageVector
        get() = when (tone) {
            Tone.Success -> KIcons.checkCircleFilled
            Tone.Info -> KIcons.infoFilled
            Tone.Warning -> KIcons.warningFilled
            Tone.Error -> KIcons.stopFilled
        }

    internal val tint: Color
        @Composable get() = when (tone) {
            Tone.Success -> KColors.positive
            Tone.Info -> KColors.brand
            Tone.Warning -> KColors.warning
            Tone.Error -> KColors.negative
        }
}

/** What a confirm sheet shows after its action ran. */
sealed interface KConfirmOutcome {
    /** Close the sheet. */
    data object Dismiss : KConfirmOutcome

    /** Stay open and show a result with a Done button. */
    data class Result(val message: KSheetMessage) : KConfirmOutcome
}

/**
 * A confirmation as a bottom sheet (the app's replacement for alerts):
 * a message, optional [details] such as a list of people, then Cancel and
 * the primary action. The primary button spins while [onConfirm] runs;
 * it can then close the sheet or show a result in place.
 *
 * For a confirmation about one item, show it with `item?.let { KConfirmSheet(...) }`.
 */
@Composable
fun KConfirmSheet(
    title: String,
    confirmTitle: String,
    onDismiss: () -> Unit,
    onConfirm: suspend () -> KConfirmOutcome,
    modifier: Modifier = Modifier,
    message: String? = null,
    isDestructive: Boolean = false,
    details: (@Composable () -> Unit)? = null,
) {
    var isWorking by remember { mutableStateOf(false) }
    var result by remember { mutableStateOf<KSheetMessage?>(null) }
    val scope = rememberCoroutineScope()
    KBottomSheet(title = if (result == null) title else "", onDismiss = onDismiss, modifier = modifier, dismissDisabled = isWorking) { close ->
        AnimatedContent(result, label = "confirm") { shown ->
            if (shown != null) {
                KResultBody(shown, stringResource(R.string.ui_done), close)
            } else {
                Column(
                    modifier = Modifier.padding(horizontal = KSpace.xl).padding(bottom = KSpace.lg),
                    verticalArrangement = Arrangement.spacedBy(KSpace.lg),
                ) {
                    if (message != null) KText(message, KTextToken.body, color = KColors.textSecondary)
                    details?.invoke()
                    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                        KButton(
                            stringResource(R.string.ui_cancel), close, Modifier.weight(1f),
                            style = KButtonStyle.Secondary, enabled = !isWorking,
                        )
                        KButton(
                            title = confirmTitle,
                            onClick = {
                                isWorking = true
                                scope.launch {
                                    val outcome = onConfirm()
                                    isWorking = false
                                    when (outcome) {
                                        KConfirmOutcome.Dismiss -> close()
                                        is KConfirmOutcome.Result -> result = outcome.message
                                    }
                                }
                            },
                            modifier = Modifier.weight(1f),
                            style = if (isDestructive) KButtonStyle.Destructive else KButtonStyle.Primary,
                            isLoading = isWorking,
                        )
                    }
                }
            }
        }
    }
}

/** A notice (an error or a result) as a bottom sheet with one OK button. Shown while [message] isn't null. */
@Composable
fun KMessageSheet(message: KSheetMessage?, onDismiss: () -> Unit) {
    if (message == null) return
    KBottomSheet(title = "", onDismiss = onDismiss) { close ->
        KResultBody(message, stringResource(R.string.ui_ok), close)
    }
}

/** An error notice for a failed action, as a bottom sheet. Shown while [failure] isn't null. */
@Composable
fun KFailureSheet(failure: Failure?, title: String, onDismiss: () -> Unit, message: String? = null) {
    if (failure == null) return
    KMessageSheet(KSheetMessage(title, message ?: failure.userMessage(), KSheetMessage.Tone.Error), onDismiss)
}

/** An icon, a title and a message, then one button. */
@Composable
internal fun KResultBody(result: KSheetMessage, buttonTitle: String, action: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = KSpace.xl).padding(bottom = KSpace.lg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        KIcon(result.icon, tint = result.tint, size = 48.dp)
        KText(result.title, KTextToken.title, textAlign = TextAlign.Center)
        KText(result.message, KTextToken.body, color = KColors.textSecondary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(KSpace.xxs))
        KButton(buttonTitle, action)
    }
}
