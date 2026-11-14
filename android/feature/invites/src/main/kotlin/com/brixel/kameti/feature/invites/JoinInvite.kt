package com.brixel.kameti.feature.invites

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.InvitePreview
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KButtonStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KSkeletonRows
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTopBar
import com.brixel.kameti.ui.helpMessage
import com.brixel.kameti.ui.userMessage
import java.time.Instant
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Loads an invite (from a link token, a 6-character code or an Inbox id)
 * and accepts or declines it.
 */
class JoinInviteViewModel(
    private val token: String?,
    private val inviteId: String?,
    dependencies: KametiDependencies,
) : ViewModel() {
    sealed interface Phase {
        data object Loading : Phase
        data class Loaded(val preview: InvitePreview) : Phase
        data class Failed(val failure: Failure) : Phase

        /** Accepted with another email: the owner has to approve first. */
        data class Waiting(val kametiName: String, val ownerName: String) : Phase
        data class Declined(val kametiName: String) : Phase
    }

    data class UiState(val phase: Phase = Phase.Loading, val isBusy: Boolean = false, val actionFailure: Failure? = null)

    private val invites = dependencies.invites
    private val current = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = current.asStateFlow()

    /** "Now" from the app clock, for "expires in" (fixed in the demo). */
    val now: Instant = dependencies.clock.now()

    suspend fun load() {
        val phase = try {
            Phase.Loaded(invites.previewInvite(token, inviteId))
        } catch (failure: Failure) {
            Phase.Failed(failure)
        }
        current.update { it.copy(phase = phase) }
    }

    /** Joins. Returns the kameti id when the member is in straight away. */
    suspend fun accept(): String? {
        val preview = (current.value.phase as? Phase.Loaded)?.preview ?: return null
        current.update { it.copy(isBusy = true, actionFailure = null) }
        try {
            val member = invites.acceptInvite(token, inviteId)
            if (member.joinStatus == JoinStatus.Joined) return member.kametiId
            current.update { it.copy(phase = Phase.Waiting(preview.kametiName, preview.ownerName)) }
        } catch (failure: Failure) {
            current.update { it.copy(actionFailure = failure) }
        } finally {
            current.update { it.copy(isBusy = false) }
        }
        return null
    }

    suspend fun decline() {
        val preview = (current.value.phase as? Phase.Loaded)?.preview ?: return
        current.update { it.copy(isBusy = true, actionFailure = null) }
        try {
            invites.declineInvite(token, inviteId)
            current.update { it.copy(phase = Phase.Declined(preview.kametiName)) }
        } catch (failure: Failure) {
            current.update { it.copy(actionFailure = failure) }
        } finally {
            current.update { it.copy(isBusy = false) }
        }
    }
}

/**
 * Accept invite (board AF-Join-Invite): who invited me, what I'd pay and
 * when my turn is, what members can see, then Join or Decline.
 */
@Composable
fun JoinInviteScreen(
    model: JoinInviteViewModel,
    onJoined: (String) -> Unit,
    onClose: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val state by model.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    LaunchedEffect(Unit) { if (model.state.value.phase is JoinInviteViewModel.Phase.Loading) model.load() }

    Column(modifier.fillMaxSize().background(KColors.background)) {
        KTopBar(stringResource(R.string.invites_invitation), onBack)
        when (val phase = state.phase) {
            JoinInviteViewModel.Phase.Loading ->
                KSkeletonRows(Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md), rows = 3)
            is JoinInviteViewModel.Phase.Failed -> Box(Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md)) {
                FailedCard(phase.failure) { scope.launch { model.load() } }
            }
            is JoinInviteViewModel.Phase.Loaded -> Loaded(phase.preview, state, model, onJoined)
            is JoinInviteViewModel.Phase.Waiting -> Outcome(
                KIcons.hourglass, stringResource(R.string.invites_waiting_for_approval),
                stringResource(R.string.invites_you_signed_in_with_a_different_email_than, phase.ownerName, phase.kametiName),
                onClose,
            )
            is JoinInviteViewModel.Phase.Declined -> Outcome(
                KIcons.closeCircle, stringResource(R.string.invites_invite_declined),
                stringResource(R.string.invites_you_wont_be_added_to_s, phase.kametiName), onClose,
            )
        }
    }
}

@Composable
private fun Loaded(
    preview: InvitePreview,
    state: JoinInviteViewModel.UiState,
    model: JoinInviteViewModel,
    onJoined: (String) -> Unit,
) {
    val scope = rememberCoroutineScope()
    var confirmingDecline by remember { mutableStateOf(false) }

    Column(Modifier.fillMaxSize()) {
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = KSpace.xl).padding(bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            Column(
                Modifier.fillMaxWidth().padding(top = KSpace.sm),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(KSpace.md),
            ) {
                Box(Modifier.size(64.dp).background(KColors.brandSubtle, CircleShape), contentAlignment = Alignment.Center) {
                    KText(
                        InviteLogic.initials(preview.ownerName), KTextStyle(size = 22f, weight = FontWeight.Bold),
                        color = KColors.onBrandSubtle,
                    )
                }
                KText(
                    // The catalog marks the name bold with asterisks; shown plain here.
                    stringResource(R.string.invites_s_invited_you_to_join, preview.ownerName).replace("**", ""),
                    KTextToken.body, color = KColors.textSecondary, textAlign = TextAlign.Center,
                )
                KText(preview.kametiName, KTextToken.titleLg, textAlign = TextAlign.Center)
            }

            val blocked = InviteLogic.blockedReason(preview)
            if (preview.isOpen && blocked != null) Warning(blocked, KIcons.personProblem)
            if (!preview.isOpen) {
                Warning(
                    if (preview.expired) {
                        stringResource(R.string.invites_this_invite_has_expired_ask_s_to_send, preview.ownerName)
                    } else {
                        stringResource(R.string.invites_this_invite_is_no_longer_open)
                    },
                    KIcons.warning,
                )
            }

            Card(padded = false) {
                val rows = buildList {
                    add(stringResource(R.string.invites_joining_as) to preview.memberName)
                    if (preview.shares.isNotEmpty()) {
                        add(stringResource(R.string.invites_you_pay_each_month) to InviteLogic.monthlyTotal(preview.shares).format())
                    }
                    InviteLogic.turnsText(preview.shares, preview.startMonth)?.let { add(stringResource(R.string.invites_your_turn) to it) }
                    val months = preview.monthsN
                    val start = preview.startMonth
                    if (months != null && preview.shares.isNotEmpty()) {
                        add(stringResource(R.string.invites_youll_receive) to InviteLogic.payout(preview.shares, months).format())
                    }
                    if (start != null && months != null) {
                        add(stringResource(R.string.invites_runs) to InviteLogic.runsText(start, months))
                    }
                    add(stringResource(R.string.invites_invite) to InviteLogic.expiryText(preview.expiresAt, model.now))
                }
                rows.forEachIndexed { index, (title, value) ->
                    Row(Modifier.fillMaxWidth().padding(vertical = KSpace.md), horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                        KText(title, KTextToken.body, color = KColors.textSecondary)
                        KText(value, KTextToken.bodyStrong, modifier = Modifier.weight(1f), textAlign = TextAlign.End)
                    }
                    if (index < rows.size - 1) KDivider()
                }
            }

            Card(padded = true) {
                Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
                    Fact(KIcons.eye, stringResource(R.string.invites_youll_see_your_dues_the_schedule_and_who, preview.ownerName))
                    Fact(KIcons.lock, stringResource(R.string.invites_other_members_see_your_name_never_your_email))
                    if (!preview.emailMatches && preview.canJoin) {
                        Fact(
                            KIcons.personWaiting,
                            stringResource(R.string.invites_youre_signed_in_with_a_different_email_than, preview.ownerName),
                        )
                    }
                }
            }

            state.actionFailure?.let { failure ->
                Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                    KIcon(KIcons.warning, tint = KColors.negative, size = 18.dp)
                    KText(failure.userMessage(), KTextToken.bodySm, color = KColors.negative)
                }
            }
        }
        if (preview.canJoin) {
            // Decline takes a third of the width, Join the rest.
            Row(
                Modifier.fillMaxWidth().padding(horizontal = KSpace.xl, vertical = KSpace.md),
                horizontalArrangement = Arrangement.spacedBy(KSpace.md),
            ) {
                KButton(
                    stringResource(R.string.invites_decline), { confirmingDecline = true }, Modifier.weight(1f),
                    style = KButtonStyle.Secondary, enabled = !state.isBusy,
                )
                KButton(
                    stringResource(R.string.invites_join_kameti),
                    onClick = { scope.launch { model.accept()?.let(onJoined) } },
                    modifier = Modifier.weight(2f), isLoading = state.isBusy,
                )
            }
        }
    }

    if (confirmingDecline) {
        KConfirmSheet(
            title = stringResource(R.string.invites_decline_this_invite),
            confirmTitle = stringResource(R.string.invites_decline),
            onDismiss = { confirmingDecline = false },
            onConfirm = {
                model.decline()
                KConfirmOutcome.Dismiss
            },
            message = stringResource(R.string.invites_s_will_see_that_you_declined_they_can, preview.ownerName),
            isDestructive = true,
        )
    }
}

@Composable
private fun Card(padded: Boolean, content: @Composable () -> Unit) {
    val shape = RoundedCornerShape(16.dp)
    Column(
        Modifier.fillMaxWidth().background(KColors.surface, shape).border(1.dp, KColors.border, shape)
            .padding(horizontal = KSpace.lg, vertical = if (padded) KSpace.lg else 0.dp),
    ) { content() }
}

@Composable
private fun Fact(icon: ImageVector, text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
        KIcon(icon, size = 18.dp)
        KText(text, KTextToken.bodySm, color = KColors.textSecondary)
    }
}

@Composable
private fun Warning(text: String, icon: ImageVector) {
    Row(
        Modifier.fillMaxWidth().background(KColors.warningSubtle, RoundedCornerShape(12.dp)).padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        KIcon(icon, tint = KColors.warning, size = 18.dp)
        KText(text, KTextToken.bodySm, color = KColors.warning)
    }
}

/**
 * AF-States: an expired or used invite gets its own card; anything else
 * (offline, a server error) can be tried again.
 */
@Composable
private fun FailedCard(failure: Failure, onRetry: () -> Unit) {
    when ((failure as? Failure.Server)?.code) {
        "invite_expired" -> KMessageCard(
            stringResource(R.string.invites_this_invite_has_expired),
            message = stringResource(R.string.invites_ask_the_person_running_the_kameti_to_send),
            icon = KIcons.envelope, tint = KColors.warning,
        )
        "invite_not_found", "invite_not_active", "invalid_invite" -> KMessageCard(
            stringResource(R.string.invites_this_invite_link_is_no_longer_valid),
            message = stringResource(R.string.invites_it_may_have_been_used_revoked_or_replaced),
            icon = KIcons.envelope, tint = KColors.warning,
        )
        else -> KMessageCard(
            stringResource(R.string.invites_cant_open_this_invite), message = failure.helpMessage(),
            actionTitle = stringResource(R.string.invites_try_again), action = onRetry,
        )
    }
}

@Composable
private fun Outcome(icon: ImageVector, title: String, message: String, onClose: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(KSpace.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KSpace.md, Alignment.CenterVertically),
    ) {
        KIcon(icon, size = 44.dp)
        KText(title, KTextToken.titleLg, textAlign = TextAlign.Center)
        KText(message, KTextToken.body, color = KColors.textSecondary, textAlign = TextAlign.Center)
        KButton(stringResource(R.string.invites_back_to_home), onClose, expand = false)
    }
}
