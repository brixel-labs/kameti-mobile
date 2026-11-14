package com.brixel.kameti.feature.invites

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.attempt
import com.brixel.kameti.domain.AppNotification
import com.brixel.kameti.domain.InviteStatus
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MyInvitation
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KRefreshable
import com.brixel.kameti.ui.KSheetMessage
import com.brixel.kameti.ui.KSkeletonRows
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.helpMessage
import com.brixel.kameti.ui.userMessage
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** Someone who accepted an invite to a kameti I run, waiting for approval. */
data class JoinRequest(val member: Member, val kametiName: String, val invitedEmail: String?, val acceptedEmail: String?) {
    val id: String get() = member.id
}

data class InboxUiState(
    val invitations: List<MyInvitation> = emptyList(),
    val requests: List<JoinRequest> = emptyList(),
    val updates: List<AppNotification> = emptyList(),
    val failure: Failure? = null,
    val hasLoaded: Boolean = false,
) {
    val isEmpty: Boolean get() = invitations.isEmpty() && requests.isEmpty() && updates.isEmpty()
    val needsYou: Int get() = invitations.size + requests.size
    val unreadUpdates: Int get() = updates.count { it.isUnread }

    /** The tab badge and app icon badge. */
    val badgeCount: Int get() = needsYou + unreadUpdates
}

/**
 * Inbox (board AN-1): what needs me (invitations to me, join requests for
 * kametis I run) and Updates, the notifications feed (FR-86).
 */
class InboxViewModel(private val userId: String, private val dependencies: KametiDependencies) : ViewModel() {
    private val current = MutableStateFlow(InboxUiState())
    val state: StateFlow<InboxUiState> = current.asStateFlow()

    /** "Now" from the app clock, for "expires in" and "2 h ago" (fixed in the demo). */
    val now: Instant = dependencies.clock.now()

    fun refresh() {
        viewModelScope.launch { load() }
    }

    suspend fun load() {
        try {
            val invitations = dependencies.invites.myInvitations()
            val found = mutableListOf<JoinRequest>()
            val mine = dependencies.kametis.listKametis().filter {
                it.isOwnedBy(userId) && (it.status == KametiStatus.Active || it.status == KametiStatus.Draft)
            }
            for (kameti in mine) {
                val waiting = attempt { dependencies.kametis.members(kameti.id) }.getOrNull().orEmpty()
                    .filter { it.joinStatus == JoinStatus.PendingApproval }
                if (waiting.isEmpty()) continue
                val invites = attempt { dependencies.invites.invites(kameti.id) }.getOrNull().orEmpty()
                for (member in waiting) {
                    val accepted = invites.firstOrNull { it.memberId == member.id && it.status == InviteStatus.Accepted }
                    found += JoinRequest(member, kameti.name, accepted?.email, accepted?.acceptedEmail)
                }
            }
            // Updates are extra: if they fail, the rest still shows.
            val updates = attempt { dependencies.notifications.notifications(limit = 60) }.getOrNull()
            current.update {
                it.copy(invitations = invitations, requests = found, updates = updates ?: it.updates, failure = null)
            }
        } catch (failure: Failure) {
            current.update { it.copy(failure = failure) }
        } finally {
            current.update { it.copy(hasLoaded = true) }
        }
    }

    /** Opening an update marks it read (at once on screen; the server follows). */
    suspend fun markRead(update: AppNotification) {
        if (!update.isUnread || current.value.updates.none { it.id == update.id }) return
        current.update { state -> state.copy(updates = state.updates.map { if (it.id == update.id) it.markedRead(now) else it }) }
        attempt { dependencies.notifications.markRead(listOf(update.id)) }
    }

    suspend fun markAllRead() {
        if (current.value.unreadUpdates == 0) return
        current.update { state -> state.copy(updates = state.updates.map { if (it.isUnread) it.markedRead(now) else it }) }
        attempt { dependencies.notifications.markRead(null) }
    }

    suspend fun decline(invitation: MyInvitation): Failure? = act { dependencies.invites.declineInvite(null, invitation.inviteId) }

    suspend fun approve(request: JoinRequest): Failure? = act { dependencies.invites.approveJoin(request.member.id) }

    suspend fun reject(request: JoinRequest): Failure? = act { dependencies.invites.declineJoin(request.member.id) }

    /** Runs one write, then reloads. Returns the failure to show, or `null`. */
    private suspend fun act(body: suspend () -> Unit): Failure? {
        try {
            body()
        } catch (failure: Failure) {
            return failure
        }
        load()
        return null
    }
}

/** How each kind of update looks, and "2 h ago". */
object InboxLogic {
    enum class Tone { Positive, Warning, Negative, Brand, Info, Neutral }

    class Style(val icon: ImageVector, val tone: Tone)

    fun style(kind: String): Style = when (kind) {
        "payment", "approved" -> Style(KIcons.check, Tone.Positive)
        "payout", "payout_soon" -> Style(KIcons.arrowUpRight, Tone.Warning)
        "payment_void", "declined", "join_declined" -> Style(KIcons.close, Tone.Negative)
        "joined" -> Style(KIcons.personFilled, Tone.Brand)
        "join_request" -> Style(KIcons.personWaiting, Tone.Info)
        "setup_reopened", "setup_restarted" -> Style(KIcons.editSetup, Tone.Info)
        "invite" -> Style(KIcons.envelope, Tone.Brand)
        "reminder", "broadcast" -> Style(KIcons.bell, Tone.Warning)
        "overdue", "owner_digest" -> Style(KIcons.error, Tone.Negative)
        else -> Style(KIcons.swap, Tone.Neutral)
    }

    /** How long ago something happened, before it is put into words. */
    sealed interface Ago {
        data object JustNow : Ago
        data class Minutes(val count: Int) : Ago
        data class Hours(val count: Int) : Ago
        data object Yesterday : Ago

        /** Two days or more: shown as a date ("8 Nov"). */
        data class On(val moment: Instant) : Ago
    }

    fun ago(moment: Instant, now: Instant): Ago {
        val seconds = maxOf(Duration.between(moment, now).seconds, 0)
        return when {
            seconds < 60 -> Ago.JustNow
            seconds < 3_600 -> Ago.Minutes((seconds / 60).toInt())
            seconds < 86_400 -> Ago.Hours((seconds / 3_600).toInt())
            seconds < 172_800 -> Ago.Yesterday
            else -> Ago.On(moment)
        }
    }

    @Composable
    fun agoText(moment: Instant, now: Instant): String = when (val ago = ago(moment, now)) {
        Ago.JustNow -> stringResource(R.string.invites_just_now)
        is Ago.Minutes -> stringResource(R.string.invites_n_min_ago, ago.count)
        is Ago.Hours -> stringResource(R.string.invites_n_h_ago, ago.count)
        Ago.Yesterday -> stringResource(R.string.invites_yesterday)
        is Ago.On -> DateTimeFormatter.ofPattern("d MMM").format(ago.moment.atZone(ZoneId.systemDefault()))
    }
}

@Composable
private fun InboxLogic.Tone.colors(): Pair<Color, Color> = when (this) {
    InboxLogic.Tone.Positive -> KColors.positive to KColors.positiveSubtle
    InboxLogic.Tone.Warning -> KColors.warning to KColors.warningSubtle
    InboxLogic.Tone.Negative -> KColors.negative to KColors.negativeSubtle
    InboxLogic.Tone.Brand -> KColors.brand to KColors.brandSubtle
    InboxLogic.Tone.Info -> KColors.info to KColors.infoSubtle
    InboxLogic.Tone.Neutral -> KColors.textSecondary to KColors.surfaceSunken
}

/**
 * Inbox (board AN-1): "Needs you" cards with their actions on top, then
 * the Updates feed with unread dots.
 */
@Composable
fun InboxScreen(
    model: InboxViewModel,
    onOpenInvitation: (String) -> Unit,
    onOpenKameti: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val state by model.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    var refreshing by remember { mutableStateOf(false) }
    var reviewing by remember { mutableStateOf<JoinRequest?>(null) }
    var declining by remember { mutableStateOf<MyInvitation?>(null) }
    var rejecting by remember { mutableStateOf<JoinRequest?>(null) }
    val wentWrong = stringResource(R.string.invites_something_went_wrong)

    LaunchedEffect(Unit) { model.load() }

    // Closes on success; shows what went wrong in the sheet otherwise.
    fun outcome(failure: Failure?): KConfirmOutcome =
        if (failure == null) {
            KConfirmOutcome.Dismiss
        } else {
            KConfirmOutcome.Result(KSheetMessage(wentWrong, failure.userMessage(context), KSheetMessage.Tone.Error))
        }

    Column(modifier.fillMaxSize().background(KColors.background)) {
        Row(
            Modifier.fillMaxWidth().padding(start = KSpace.gutter, end = KSpace.sm, top = KSpace.lg, bottom = KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            KText(stringResource(R.string.invites_inbox), KTextToken.display, modifier = Modifier.weight(1f))
            if (state.unreadUpdates > 0) {
                KText(
                    stringResource(R.string.invites_mark_all_read), KTextToken.bodyStrong, color = KColors.brand,
                    modifier = Modifier.clip(RoundedCornerShape(8.dp))
                        .clickable(role = Role.Button) { scope.launch { model.markAllRead() } }
                        .padding(KSpace.sm),
                )
            }
        }
        KRefreshable(
            isRefreshing = refreshing,
            onRefresh = {
                scope.launch {
                    refreshing = true
                    model.load()
                    refreshing = false
                }
            },
            modifier = Modifier.weight(1f),
        ) {
            Column(
                Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = KSpace.xl).padding(bottom = KSpace.xl),
                verticalArrangement = Arrangement.spacedBy(KSpace.sm),
            ) {
                val failure = state.failure
                when {
                    !state.hasLoaded -> KSkeletonRows(rows = 3)
                    failure != null && state.isEmpty -> KMessageCard(
                        stringResource(R.string.invites_couldnt_load_your_inbox), message = failure.helpMessage(),
                        actionTitle = stringResource(R.string.invites_try_again), action = { model.refresh() },
                    )
                    state.isEmpty -> Column(
                        Modifier.fillMaxWidth().padding(top = 96.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(KSpace.sm),
                    ) {
                        KIcon(KIcons.inbox, size = 44.dp)
                        KText(stringResource(R.string.invites_youre_all_caught_up), KTextToken.titleLg, textAlign = TextAlign.Center)
                        KText(
                            stringResource(R.string.invites_invitations_join_requests_and_updates_about_your_kametis),
                            KTextToken.body, color = KColors.textSecondary, textAlign = TextAlign.Center,
                        )
                    }
                    else -> {
                        if (state.needsYou > 0) {
                            SectionTitle(stringResource(R.string.invites_needs_you_n, state.needsYou))
                            state.requests.forEach { request ->
                                ActionCard(
                                    KIcons.personWaiting, InboxLogic.Tone.Info,
                                    title = stringResource(R.string.invites_s_wants_to_join, request.member.name),
                                    detail = stringResource(R.string.invites_s_signed_in_with_a_different_email, request.kametiName),
                                    primary = stringResource(R.string.invites_review),
                                    onPrimary = { reviewing = request }, onDecline = { rejecting = request },
                                )
                            }
                            state.invitations.forEach { invitation ->
                                ActionCard(
                                    KIcons.envelope, InboxLogic.Tone.Brand,
                                    title = stringResource(R.string.invites_s_invited_you, invitation.ownerName),
                                    detail = "${invitation.kametiName} · ${InviteLogic.expiryText(invitation.expiresAt, model.now)}",
                                    primary = stringResource(R.string.invites_view_and_join),
                                    onPrimary = { onOpenInvitation(invitation.inviteId) }, onDecline = { declining = invitation },
                                )
                            }
                        }
                        if (state.updates.isNotEmpty()) {
                            SectionTitle(
                                stringResource(R.string.invites_updates),
                                Modifier.padding(top = if (state.needsYou > 0) KSpace.md else 0.dp),
                            )
                            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(KColors.surface)) {
                                state.updates.forEachIndexed { index, update ->
                                    UpdateRow(update, model.now, last = index == state.updates.size - 1) {
                                        scope.launch { model.markRead(update) }
                                        val kametiId = update.kametiId
                                        if (update.opensKameti && kametiId != null) onOpenKameti(kametiId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    reviewing?.let { request ->
        ApproveJoinSheet(
            memberName = request.member.name, invitedEmail = request.invitedEmail, acceptedEmail = request.acceptedEmail,
            approve = { model.approve(request) }, reject = { model.reject(request) }, onDismiss = { reviewing = null },
        )
    }
    declining?.let { invitation ->
        KConfirmSheet(
            title = stringResource(R.string.invites_decline_this_invite),
            confirmTitle = stringResource(R.string.invites_decline),
            onDismiss = { declining = null },
            onConfirm = { outcome(model.decline(invitation)) },
            message = stringResource(R.string.invites_s_will_see_that_you_declined_s, invitation.ownerName, invitation.kametiName),
            isDestructive = true,
        )
    }
    rejecting?.let { request ->
        KConfirmSheet(
            title = stringResource(R.string.invites_decline_s_s_request, request.member.name),
            confirmTitle = stringResource(R.string.invites_decline),
            onDismiss = { rejecting = null },
            onConfirm = { outcome(model.reject(request)) },
            message = stringResource(R.string.invites_they_wont_be_linked_to_s_you_can, request.kametiName),
            isDestructive = true,
        )
    }
}

@Composable
private fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    KText(
        text.uppercase(), KTextToken.label, color = KColors.textSecondary,
        modifier = modifier.padding(top = KSpace.md, bottom = KSpace.xxs).padding(horizontal = KSpace.xxs),
    )
}

@Composable
private fun RoundIcon(icon: ImageVector, tone: InboxLogic.Tone) {
    val (tint, background) = tone.colors()
    Box(Modifier.size(38.dp).background(background, CircleShape), contentAlignment = Alignment.Center) {
        KIcon(icon, tint = tint, size = 18.dp)
    }
}

/** Something that needs an answer: Decline beside the main action, half the width each. */
@Composable
private fun ActionCard(
    icon: ImageVector,
    tone: InboxLogic.Tone,
    title: String,
    detail: String,
    primary: String,
    onPrimary: () -> Unit,
    onDecline: () -> Unit,
) {
    val shape = RoundedCornerShape(16.dp)
    Column(
        Modifier.fillMaxWidth().background(KColors.surface, shape).border(1.dp, KColors.border, shape).padding(KSpace.lg),
        verticalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
            RoundIcon(icon, tone)
            Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                KText(title, KTextToken.bodyStrong)
                KText(detail, KTextToken.bodySm, color = KColors.textSecondary)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
            Box(
                Modifier.weight(1f).heightIn(min = 44.dp).clip(CircleShape).border(1.dp, KColors.border, CircleShape)
                    .clickable(role = Role.Button, onClick = onDecline),
                contentAlignment = Alignment.Center,
            ) {
                KText(stringResource(R.string.invites_decline), KTextToken.bodyStrong)
            }
            Box(
                Modifier.weight(1f).heightIn(min = 44.dp).clip(CircleShape).background(KColors.brand)
                    .clickable(role = Role.Button, onClick = onPrimary),
                contentAlignment = Alignment.Center,
            ) {
                KText(primary, KTextToken.bodyStrong, color = KColors.textOnBrand)
            }
        }
    }
}

/** One update. The whole row opens it (and marks it read). */
@Composable
private fun UpdateRow(update: AppNotification, now: Instant, last: Boolean, onClick: () -> Unit) {
    val style = InboxLogic.style(update.kind)
    Column(Modifier.clickable(role = Role.Button, onClick = onClick).padding(horizontal = KSpace.lg)) {
        Row(Modifier.padding(vertical = KSpace.md), horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
            RoundIcon(style.icon, style.tone)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                KText(update.title, KTextToken.bodyStrong)
                KText(update.body, KTextToken.bodySm, color = KColors.textSecondary)
                KText(InboxLogic.agoText(update.createdAt, now), KTextToken.caption, color = KColors.textSecondary)
            }
            if (update.isUnread) {
                Box(Modifier.padding(top = 6.dp).size(8.dp).background(KColors.brand, CircleShape)) {
                    KIcon(KIcons.circle, tint = Color.Transparent, size = 8.dp, label = stringResource(R.string.invites_unread))
                }
            }
        }
        if (!last) KDivider()
    }
}
