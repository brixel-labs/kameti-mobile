package com.brixel.kameti.feature.kametidetail

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KConnectivity
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KFailureSheet
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIconButton
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KLiveUpdates
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KOfflineBanner
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KRefreshable
import com.brixel.kameti.ui.KSheetMessage
import com.brixel.kameti.ui.KSkeletonRows
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTopBar
import com.brixel.kameti.ui.helpMessage
import com.brixel.kameti.ui.userMessage
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * One kameti: the owner's tabs or the member's read-only view. Owner or
 * member is decided once, from the loaded kameti; the member branch builds
 * no write controls at all.
 */
@Composable
fun KametiDetailScreen(
    model: KametiDetailViewModel,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    onResumeDraft: ((String) -> Unit)? = null,
    onOpenActivity: ((String) -> Unit)? = null,
    onArchived: (() -> Unit)? = null,
) {
    val state by model.state.collectAsStateWithLifecycle()
    val loaded = (state as? KametiDetailViewModel.State.Loaded)?.data
    var showingMenu by remember { mutableStateOf(false) }
    // The owner's ••• menu (board AE-2): Edit, Activity, Archive / Restore.
    val hasMenu = loaded != null && loaded.kameti.status != KametiStatus.Draft && (loaded.isOwner || onOpenActivity != null)
    // The kameti to name the screen after: the loaded one, else what Home passed.
    val known = (state as? KametiDetailViewModel.State.Loaded)?.data?.kameti ?: model.preview

    LaunchedEffect(Unit) { model.load() }
    // Live: reload quietly when this kameti changes on the server.
    val live = KLiveUpdates.shared
    LaunchedEffect(live.revision) {
        if (live.revision > 0 && live.affects(model.kametiId)) model.load()
    }

    Column(modifier.fillMaxSize().background(KColors.background)) {
        KTopBar(
            title = known?.name ?: stringResource(R.string.detail_kameti),
            onBack = onBack,
            subtitle = known?.let {
                stringResource(R.string.detail_n_months_s_per_slot, it.monthsN, it.slotAmountC.format())
            },
            trailing = if (hasMenu) {
                { KIconButton(KIcons.more, stringResource(R.string.detail_more), onClick = { showingMenu = true }, tint = KColors.textPrimary) }
            } else {
                null
            },
        )
        when (val current = state) {
            KametiDetailViewModel.State.Loading -> Column(
                Modifier.verticalScroll(rememberScrollState()).padding(horizontal = KSpace.xl).padding(top = KSpace.md),
                verticalArrangement = Arrangement.spacedBy(KSpace.md),
            ) {
                KSkeletonRows(rows = 2)
                KSkeletonRows(rows = 4)
            }
            is KametiDetailViewModel.State.Failed -> Box(Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md)) {
                KMessageCard(
                    title = stringResource(R.string.detail_couldnt_load_this_kameti),
                    message = current.failure.helpMessage(),
                    actionTitle = stringResource(R.string.detail_try_again),
                    action = { model.refresh() },
                )
            }
            is KametiDetailViewModel.State.Loaded -> {
                // Offline: the last loaded data stays, with a note on how old it is.
                if (!KConnectivity.isOnline) {
                    KOfflineBanner(
                        since = model.loadedAt,
                        modifier = Modifier.padding(horizontal = KSpace.xl, vertical = KSpace.sm),
                    )
                }
                Loaded(current.data, model, onResumeDraft)
            }
        }
    }

    if (loaded != null) {
        MoreMenu(
            data = loaded, model = model, isShowing = showingMenu, onHide = { showingMenu = false },
            title = known?.name ?: stringResource(R.string.detail_kameti),
            onResumeDraft = onResumeDraft, onOpenActivity = onOpenActivity, onArchived = onArchived,
        )
    }
}

/** What went wrong when archiving, restoring or duplicating, in words. */
@Composable
internal fun changeFailureMessage(failure: Failure): String = changeFailureMessage(failure, LocalContext.current)

internal fun changeFailureMessage(failure: Failure, context: Context): String =
    changeFailureHint(failure)?.let(context::getString) ?: failure.userMessage(context)

/** The app's own explanation for a failed change, when the general message wouldn't say how to fix it. */
internal fun changeFailureHint(failure: Failure): Int? =
    if ((failure as? Failure.Server)?.code == "kameti_name_taken") R.string.detail_you_already_have_a_running_kameti_with_this else null

/**
 * The ••• menu as a short sheet of actions, with the confirmations each one
 * needs: Edit kameti, Edit setup, Activity, Duplicate, Archive or Restore.
 */
@Composable
private fun MoreMenu(
    data: KametiDetailData,
    model: KametiDetailViewModel,
    isShowing: Boolean,
    onHide: () -> Unit,
    title: String,
    onResumeDraft: ((String) -> Unit)?,
    onOpenActivity: ((String) -> Unit)?,
    onArchived: (() -> Unit)?,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var editing by remember { mutableStateOf(false) }
    var confirmingArchive by remember { mutableStateOf(false) }
    var confirmingDuplicate by remember { mutableStateOf(false) }
    var confirmingEditSetup by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    val couldnt = stringResource(R.string.detail_couldnt_change_this_kameti)
    val status = data.kameti.status

    fun failed(failure: Failure, heading: String = couldnt, message: String = changeFailureMessage(failure, context)) =
        KConfirmOutcome.Result(KSheetMessage(heading, message, KSheetMessage.Tone.Error))

    if (isShowing) {
        KBottomSheet(title = title, onDismiss = onHide) { close ->
            Column(Modifier.padding(horizontal = KSpace.xl).padding(bottom = KSpace.xl)) {
                if (data.isOwner && status == KametiStatus.Active) {
                    MenuRow(KIcons.edit, stringResource(R.string.detail_edit_kameti)) {
                        close()
                        editing = true
                    }
                }
                // Before the first month, with nothing recorded: back to setup.
                if (SetupLogic.canEditSetup(data) && onResumeDraft != null) {
                    MenuRow(KIcons.editSetup, stringResource(R.string.detail_edit_setup)) {
                        close()
                        confirmingEditSetup = true
                    }
                }
                if (onOpenActivity != null) {
                    MenuRow(
                        KIcons.history,
                        stringResource(if (data.isOwner) R.string.detail_activity else R.string.detail_your_activity),
                    ) {
                        close()
                        onOpenActivity(data.kameti.id)
                    }
                }
                if (data.isOwner && onResumeDraft != null) {
                    MenuRow(KIcons.duplicate, stringResource(R.string.detail_duplicate_kameti)) {
                        close()
                        confirmingDuplicate = true
                    }
                }
                if (data.isOwner) {
                    if (status == KametiStatus.Archived) {
                        MenuRow(KIcons.undo, stringResource(R.string.detail_restore_kameti)) {
                            close()
                            scope.launch { failure = model.restore() }
                        }
                    } else {
                        KDivider(Modifier.padding(vertical = KSpace.sm))
                        MenuRow(KIcons.archive, stringResource(R.string.detail_archive_kameti), isDestructive = true) {
                            close()
                            confirmingArchive = true
                        }
                    }
                }
            }
        }
    }

    if (editing) EditKametiSheet(data, model) { editing = false }
    if (confirmingArchive) {
        KConfirmSheet(
            title = stringResource(R.string.detail_archive_s, title),
            confirmTitle = stringResource(R.string.detail_archive),
            onDismiss = { confirmingArchive = false },
            onConfirm = {
                model.archive()?.let { failed(it) } ?: run {
                    // Back to Home once the sheet has finished closing.
                    scope.launch {
                        delay(350)
                        onArchived?.invoke()
                    }
                    KConfirmOutcome.Dismiss
                }
            },
            message = stringResource(R.string.detail_it_becomes_read_only_for_you_and_every),
            isDestructive = true,
        )
    }
    if (confirmingDuplicate) {
        KConfirmSheet(
            title = stringResource(R.string.detail_duplicate_s, title),
            confirmTitle = stringResource(R.string.detail_duplicate),
            onDismiss = { confirmingDuplicate = false },
            onConfirm = {
                val result = model.duplicate { attempt ->
                    if (attempt <= 1) context.getString(R.string.detail_copy_b9f2) else context.getString(R.string.detail_copy_n, attempt)
                }
                when (result) {
                    is Attempt.Success -> {
                        // Let the sheet finish closing before the draft opens.
                        scope.launch {
                            delay(450)
                            onResumeDraft?.invoke(result.value)
                        }
                        KConfirmOutcome.Dismiss
                    }
                    is Attempt.Failed -> failed(result.failure)
                }
            },
            message = stringResource(R.string.detail_a_new_draft_with_the_same_members_shares),
        )
    }
    if (confirmingEditSetup) {
        KConfirmSheet(
            title = stringResource(R.string.detail_edit_the_setup),
            confirmTitle = stringResource(R.string.detail_edit_setup),
            onDismiss = { confirmingEditSetup = false },
            onConfirm = {
                val reopenFailure = model.reopen()
                if (reopenFailure != null) {
                    failed(reopenFailure, context.getString(R.string.detail_cant_edit_the_setup), reopenFailure.userMessage(context))
                } else {
                    // Let the sheet close, then open the setup steps.
                    scope.launch {
                        delay(450)
                        onResumeDraft?.invoke(model.kametiId)
                    }
                    KConfirmOutcome.Dismiss
                }
            },
            message = stringResource(R.string.detail_it_goes_back_to_setup_until_you_start),
        )
    }
    KFailureSheet(failure, couldnt, onDismiss = { failure = null }, message = failure?.let { changeFailureMessage(it, context) })
}

@Composable
private fun MenuRow(icon: ImageVector, title: String, isDestructive: Boolean = false, onClick: () -> Unit) {
    val color = if (isDestructive) KColors.negative else KColors.textPrimary
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            .clip(RoundedCornerShape(KRadius.input))
            .clickable(role = Role.Button, onClick = onClick),
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(icon, tint = if (isDestructive) KColors.negative else KColors.brand)
        KText(title, KTextToken.body, color = color)
    }
}

@Composable
private fun Loaded(data: KametiDetailData, model: KametiDetailViewModel, onResumeDraft: ((String) -> Unit)?) {
    val scope = rememberCoroutineScope()
    var refreshing by remember { mutableStateOf(false) }
    when {
        !data.isOwner -> KRefreshable(
            isRefreshing = refreshing,
            onRefresh = {
                scope.launch {
                    refreshing = true
                    model.load()
                    refreshing = false
                }
            },
        ) {
            MemberView(data)
        }
        data.kameti.status == KametiStatus.Draft -> Column(
            Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            KMessageCard(
                title = stringResource(R.string.detail_this_kameti_is_a_draft),
                message = stringResource(R.string.detail_finish_setting_it_up_to_start_collecting),
                icon = KIcons.editSetup,
            )
            if (onResumeDraft != null) {
                KButton(stringResource(R.string.detail_continue_setting_up), onClick = { onResumeDraft(data.kameti.id) })
            }
        }
        else -> OwnerTabs(data, model)
    }
}
