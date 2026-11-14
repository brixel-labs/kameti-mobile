package com.brixel.kameti.feature.home

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.core.RecordAction
import com.brixel.kameti.domain.MyInvitation
import com.brixel.kameti.feature.invites.InvitationCard
import com.brixel.kameti.feature.kametidetail.DetailLogic
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KConnectivity
import com.brixel.kameti.ui.KEmptyIllustration
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KOfflineBanner
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KRefreshable
import com.brixel.kameti.ui.KSectionHeader
import com.brixel.kameti.ui.KSheetMessage
import com.brixel.kameti.ui.KSize
import com.brixel.kameti.ui.KSkeletonRows
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTopBar
import com.brixel.kameti.ui.helpMessage
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.textSubtitle
import com.brixel.kameti.ui.userMessage
import kotlinx.coroutines.launch

/**
 * Home (boards Main, AF-Empty-Home, AD-Home): "Running by me", "I'm a
 * member" and "Past", or the first-time empty state.
 */
@Composable
fun HomeScreen(
    model: HomeViewModel,
    onOpen: (String) -> Unit,
    onRecord: (String, RecordAction) -> Unit,
    onCreate: () -> Unit,
    onJoin: (String) -> Unit,
    onOpenInvitation: (String) -> Unit,
    onOpenArchived: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val state by model.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    var refreshing by remember { mutableStateOf(false) }
    var enteringCode by rememberSaveable { mutableStateOf(false) }
    var recording by rememberSaveable { mutableStateOf(false) }
    var declining by remember { mutableStateOf<MyInvitation?>(null) }
    // Owner kametis that are collecting this month.
    val recordable = state.sections.mine.filter { it.currentMonth != null }

    LaunchedEffect(Unit) { model.load() }

    Box(modifier.fillMaxSize().background(KColors.background)) {
        Column(Modifier.fillMaxSize()) {
            KText(
                state.firstName ?: stringResource(R.string.home_kameti),
                KTextToken.display,
                modifier = Modifier.padding(start = KSpace.xl, end = KSpace.xl, top = KSpace.lg, bottom = KSpace.sm),
                maxLines = 1,
            )
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
                val failure = state.failure
                when {
                    !state.hasLoaded -> Column(
                        Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(horizontal = KSpace.xl)
                            .padding(top = KSpace.md),
                        verticalArrangement = Arrangement.spacedBy(KSpace.md),
                    ) {
                        KSkeletonRows(rows = 3)
                        KSkeletonRows(rows = 2)
                    }
                    failure != null && state.sections.isEmpty -> Column(
                        Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(horizontal = KSpace.xl)
                            .padding(top = KSpace.md),
                    ) {
                        KMessageCard(
                            title = stringResource(R.string.home_couldnt_load_your_kametis),
                            message = failure.helpMessage(),
                            actionTitle = stringResource(R.string.home_try_again),
                            action = { model.refresh() },
                        )
                    }
                    else -> LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(
                            start = KSpace.xl,
                            end = KSpace.xl,
                            // Room for the Record payment button over the last card.
                            bottom = if (recordable.isEmpty()) KSpace.xl else KSpace.xl + 76.dp,
                        ),
                        verticalArrangement = Arrangement.spacedBy(KSpace.md),
                    ) {
                        if (!KConnectivity.isOnline) item(key = "offline") { KOfflineBanner(since = state.loadedAt) }
                        if (state.invitations.isNotEmpty()) {
                            item(key = "invitations") { KSectionHeader(stringResource(R.string.home_invitations)) }
                            items(state.invitations, key = { "invite-${it.inviteId}" }) { invitation ->
                                InvitationCard(
                                    invitation = invitation,
                                    now = model.now,
                                    onDecline = { declining = invitation },
                                    onReview = { onOpenInvitation(invitation.inviteId) },
                                )
                            }
                        }
                        if (state.sections.isEmpty) {
                            item(key = "empty") { EmptyHome(onCreate) }
                            item(key = "code") { InviteCodeCard(onJoin) }
                            item(key = "hint") { EmailInvitesHint() }
                        }
                        // "New kameti" sits on the first group's header.
                        val hasMine = state.sections.mine.isNotEmpty()
                        group(R.string.home_running_by_me, state.sections.mine, model, onOpen, onNew = onCreate)
                        group(
                            R.string.home_im_a_member, state.sections.joined, model, onOpen,
                            onNew = if (hasMine) null else onCreate,
                        )
                        group(
                            R.string.home_past, state.sections.past, model, onOpen,
                            archivedCount = state.sections.archived.size, onOpenArchived = onOpenArchived,
                        )
                        if (!state.sections.isEmpty) {
                            item(key = "have-code") {
                                Box(
                                    Modifier
                                        .fillMaxWidth()
                                        .heightIn(min = KSize.minTouch)
                                        .clip(RoundedCornerShape(KRadius.input))
                                        .clickable(role = Role.Button) { enteringCode = true },
                                    contentAlignment = Alignment.Center,
                                ) {
                                    KText(
                                        stringResource(R.string.home_have_an_invite_code),
                                        KTextToken.bodyStrong,
                                        color = KColors.brand,
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        if (recordable.isNotEmpty()) {
            RecordButton(
                onClick = { recording = true },
                modifier = Modifier.align(Alignment.BottomEnd).padding(KSpace.xl),
            )
        }
    }

    if (enteringCode) {
        KBottomSheet(title = stringResource(R.string.home_join_with_a_code), onDismiss = { enteringCode = false }) { close ->
            Box(Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.xl)) {
                InviteCodeCard { code ->
                    close()
                    onJoin(code)
                }
            }
        }
    }

    if (recording) {
        KBottomSheet(title = stringResource(R.string.home_record_payment), onDismiss = { recording = false }) { close ->
            RecordActions(recordable) { id, action ->
                close()
                onRecord(id, action)
            }
        }
    }

    declining?.let { invitation ->
        KConfirmSheet(
            title = stringResource(R.string.home_decline_this_invite),
            confirmTitle = stringResource(R.string.home_decline),
            onDismiss = { declining = null },
            onConfirm = {
                val failure = model.decline(invitation)
                if (failure == null) {
                    KConfirmOutcome.Dismiss
                } else {
                    KConfirmOutcome.Result(
                        KSheetMessage(
                            context.getString(R.string.home_couldnt_decline),
                            failure.userMessage(context),
                            KSheetMessage.Tone.Error,
                        ),
                    )
                }
            },
            message = stringResource(
                R.string.home_s_will_see_that_you_declined_s,
                invitation.ownerName,
                invitation.kametiName,
            ),
            isDestructive = true,
        )
    }
}

/** One of Home's groups: its header, its cards, and for Past the Archived row. */
private fun LazyListScope.group(
    titleRes: Int,
    items: List<HomeKametiSummary>,
    model: HomeViewModel,
    onOpen: (String) -> Unit,
    onNew: (() -> Unit)? = null,
    archivedCount: Int = 0,
    onOpenArchived: () -> Unit = {},
) {
    if (items.isEmpty() && archivedCount == 0) return
    item(key = "header-$titleRes") {
        KSectionHeader(
            stringResource(titleRes),
            actionTitle = if (onNew != null) stringResource(R.string.home_new_kameti) else null,
            action = onNew,
        )
    }
    items(items, key = { it.id }) { item ->
        HomeKametiCard(item, model.currentMonth) { onOpen(item.id) }
    }
    if (archivedCount > 0) {
        item(key = "archived") { ArchivedRow(archivedCount, onOpenArchived) }
    }
}

/** First time: nothing yet, so say what to do. */
@Composable
private fun EmptyHome(onCreate: () -> Unit) {
    KCard {
        Column(
            Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            KEmptyIllustration()
            KText(stringResource(R.string.home_no_kametis_yet), KTextToken.titleLg)
            KText(
                stringResource(R.string.home_start_one_for_your_family_office_or_friends),
                KTextToken.body,
                color = KColors.textSecondary,
                textAlign = TextAlign.Center,
            )
            KButton(stringResource(R.string.home_start_a_kameti), onClick = onCreate, icon = KIcons.plus)
        }
    }
}

@Composable
private fun EmailInvitesHint() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(KColors.infoSubtle, RoundedCornerShape(KRadius.card))
            .padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        KIcon(KIcons.info, tint = KColors.info, size = 18.dp)
        KText(stringResource(R.string.home_invites_sent_to_your_email_show_up_here), KTextToken.bodySm, color = KColors.info)
    }
}

/** The floating "Record payment" button over the list. */
@Composable
private fun RecordButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(KRadius.card)
    Row(
        modifier = modifier
            .shadow(10.dp, shape)
            .clip(shape)
            .background(KColors.brand)
            .clickable(role = Role.Button, onClick = onClick)
            .heightIn(min = 52.dp)
            .padding(horizontal = KSpace.lg),
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(KIcons.plus, tint = KColors.textOnBrand)
        KText(stringResource(R.string.home_record_payment), KTextToken.bodyStrong, color = KColors.textOnBrand)
    }
}

/**
 * Record payment: what to do, on which of my kametis. With one kameti its
 * actions show straight away; with several each is listed under its name.
 */
@Composable
private fun RecordActions(recordable: List<HomeKametiSummary>, onPick: (String, RecordAction) -> Unit) {
    Column(
        Modifier
            .verticalScroll(rememberScrollState())
            .padding(horizontal = KSpace.xl)
            .padding(bottom = KSpace.xl),
    ) {
        recordable.forEachIndexed { index, item ->
            if (index > 0) KDividerSpace()
            KSectionHeader(item.kameti.name)
            val month = item.currentMonth?.let { DetailLogic.monthName(it.monthStart) }.orEmpty()
            if (!item.isPaidOut && item.recipients.isNotEmpty()) {
                ActionRow(KIcons.arrowUpRight, stringResource(R.string.home_pay_out_s, month)) {
                    onPick(item.id, RecordAction.PayOut)
                }
            }
            ActionRow(KIcons.plus, stringResource(R.string.home_record_one_payment)) {
                onPick(item.id, RecordAction.RecordOne)
            }
            ActionRow(KIcons.checklist, stringResource(R.string.home_collect_s_tap_to_settle, month)) {
                onPick(item.id, RecordAction.Collect)
            }
        }
    }
}

@Composable
private fun KDividerSpace() {
    Box(Modifier.padding(vertical = KSpace.sm)) { com.brixel.kameti.ui.KDivider() }
}

@Composable
private fun ActionRow(icon: ImageVector, title: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            .clip(RoundedCornerShape(KRadius.input))
            .clickable(role = Role.Button, onClick = onClick),
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(icon, tint = KColors.brand)
        KText(title, KTextToken.body, modifier = Modifier.weight(1f))
        KIcon(KIcons.chevronRight, size = 18.dp)
    }
}

/**
 * "Have an invite code?" (board AF-Empty-Home): the 6-character code from
 * the invite email, opened like the link.
 */
@Composable
internal fun InviteCodeCard(onJoin: (String) -> Unit) {
    var code by rememberSaveable { mutableStateOf("") }
    val trimmed = code.trim()
    val join = { if (trimmed.isNotEmpty()) onJoin(trimmed) }
    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
            Column(verticalArrangement = Arrangement.spacedBy(KSpace.xs)) {
                KText(stringResource(R.string.home_have_an_invite_code), KTextToken.bodyStrong)
                KText(
                    stringResource(R.string.home_its_in_the_email_from_the_person_running),
                    KTextToken.subtitle,
                    color = KColors.textSubtitle,
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                KTextField(
                    text = code,
                    onTextChange = { code = it.uppercase() },
                    modifier = Modifier.weight(1f),
                    placeholder = stringResource(R.string.home_e_g_k7q2mx),
                    capitalization = KeyboardCapitalization.Characters,
                    imeAction = ImeAction.Go,
                    onImeAction = join,
                )
                val shape = RoundedCornerShape(KRadius.input)
                Box(
                    Modifier
                        .alpha(if (trimmed.isEmpty()) 0.5f else 1f)
                        .heightIn(min = KSize.inputHeight)
                        .clip(shape)
                        .border(1.dp, KColors.brand, shape)
                        .clickable(enabled = trimmed.isNotEmpty(), role = Role.Button, onClick = join)
                        .padding(horizontal = KSpace.lg),
                    contentAlignment = Alignment.Center,
                ) {
                    KText(stringResource(R.string.home_join), KTextToken.bodyStrong, color = KColors.brand)
                }
            }
        }
    }
}

/** The last row of Past: opens the archived kametis (§6.11). */
@Composable
private fun ArchivedRow(count: Int, onClick: () -> Unit) {
    KCard(onClick = onClick) {
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md), verticalAlignment = Alignment.CenterVertically) {
            KIcon(KIcons.archive)
            KText(stringResource(R.string.home_archived_n, count), KTextToken.bodyStrong, modifier = Modifier.weight(1f))
            KIcon(KIcons.chevronRight, size = 18.dp)
        }
    }
}

/** Archived kametis (§6.11): read-only, each opens with Restore. */
@Composable
fun ArchivedKametisScreen(model: HomeViewModel, onBack: () -> Unit, onOpen: (String) -> Unit, modifier: Modifier = Modifier) {
    val state by model.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    var refreshing by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { model.load() }
    Column(modifier.fillMaxSize().background(KColors.background)) {
        KTopBar(stringResource(R.string.home_archived), onBack)
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
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = KSpace.xl, vertical = KSpace.md),
                verticalArrangement = Arrangement.spacedBy(KSpace.md),
            ) {
                if (state.sections.archived.isEmpty()) {
                    item {
                        KMessageCard(
                            title = stringResource(R.string.home_nothing_archived),
                            message = stringResource(R.string.home_kametis_you_archive_move_here_open_one_to),
                            icon = KIcons.archive,
                        )
                    }
                } else {
                    item {
                        KText(
                            stringResource(R.string.home_read_only_for_you_and_every_member_open),
                            KTextToken.bodySm,
                            color = KColors.textSecondary,
                        )
                    }
                    items(state.sections.archived, key = { it.id }) { item ->
                        HomeKametiCard(item, model.currentMonth) { onOpen(item.id) }
                    }
                }
            }
        }
    }
}
