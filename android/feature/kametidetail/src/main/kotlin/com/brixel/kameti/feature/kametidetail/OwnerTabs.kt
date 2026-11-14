package com.brixel.kameti.feature.kametidetail

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
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
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.RecordAction
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.MonthCollectionState
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.ui.KAvatarStack
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KFlowRow
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KMoneyStyle
import com.brixel.kameti.ui.KMoneyText
import com.brixel.kameti.ui.KMoneyTone
import com.brixel.kameti.ui.KMonthGrid
import com.brixel.kameti.ui.KOption
import com.brixel.kameti.ui.KPaidOutStrip
import com.brixel.kameti.ui.KPaymentStatus
import com.brixel.kameti.ui.KPerson
import com.brixel.kameti.ui.KPill
import com.brixel.kameti.ui.KPotHeadline
import com.brixel.kameti.ui.KPotProgress
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KRefreshable
import com.brixel.kameti.ui.KSectionHeader
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KStatusChip
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KUnderlineTabs
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import java.time.LocalDate
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

internal enum class OwnerTab { Overview, Members, Schedule, Payments }

/**
 * The owner's view of a running kameti (boards A-Overview, A2-*-Tab):
 * Overview, Members, Schedule and Payments. Swipe sideways or tap a tab.
 */
@Composable
internal fun OwnerTabs(data: KametiDetailData, model: KametiDetailViewModel, modifier: Modifier = Modifier) {
    val tabs = listOf(
        KOption(OwnerTab.Overview, stringResource(R.string.detail_overview)),
        KOption(OwnerTab.Members, stringResource(R.string.detail_members)),
        KOption(OwnerTab.Schedule, stringResource(R.string.detail_schedule)),
        KOption(OwnerTab.Payments, stringResource(R.string.detail_payments)),
    )
    val pager = rememberPagerState { tabs.size }
    val scope = rememberCoroutineScope()
    var refreshing by remember { mutableStateOf(false) }
    val isArchived = data.kameti.status == KametiStatus.Archived
    val current = data.current
    val monthName = current?.let { DetailLogic.monthName(it.monthStart) }.orEmpty()
    val canPayOutNow = !isArchived && current != null && canPayOut(data, current)

    var choosingAction by remember { mutableStateOf(false) }
    var recording by remember { mutableStateOf<RecordTarget?>(null) }
    var collecting by remember { mutableStateOf(false) }
    var voiding by remember { mutableStateOf<VoidTarget?>(null) }
    var payingOut by remember { mutableStateOf<Int?>(null) }
    var reminding by remember { mutableStateOf(false) }

    // Home's Record payment opens the kameti and starts the chosen action.
    LaunchedEffect(Unit) {
        val action = model.pendingAction ?: return@LaunchedEffect
        model.pendingAction = null
        if (isArchived) return@LaunchedEffect
        delay(450)
        when (action) {
            RecordAction.PayOut -> if (canPayOutNow) payingOut = current?.monthIndex
            RecordAction.RecordOne -> recording = RecordTarget(null)
            RecordAction.Collect -> collecting = true
        }
    }

    Box(modifier.fillMaxSize()) {
    Column(Modifier.fillMaxSize()) {
        if (isArchived) {
            ArchivedBanner(Modifier.padding(horizontal = KSpace.xl, vertical = KSpace.sm))
        }
        KUnderlineTabs(
            tabs = tabs,
            selection = tabs[pager.currentPage].value,
            onSelect = { tab -> scope.launch { pager.animateScrollToPage(tabs.indexOfFirst { it.value == tab }) } },
            inset = KSpace.xl,
        )
        HorizontalPager(state = pager, modifier = Modifier.weight(1f), beyondViewportPageCount = 1) { page ->
            KRefreshable(
                isRefreshing = refreshing,
                onRefresh = {
                    scope.launch {
                        refreshing = true
                        model.load()
                        refreshing = false
                    }
                },
            ) {
                Column(
                    Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = KSpace.xl)
                        // Room for the floating action.
                        .padding(top = KSpace.lg, bottom = if (current != null && !isArchived) 88.dp else KSpace.xl),
                    verticalArrangement = Arrangement.spacedBy(KSpace.lg),
                ) {
                    when (tabs[page].value) {
                        OwnerTab.Overview -> OverviewTab(
                            data,
                            onRemind = if (isArchived || data.kameti.status != KametiStatus.Active) null else ({ reminding = true }),
                            onPayOut = if (canPayOutNow) ({ payingOut = current?.monthIndex }) else null,
                            onRecord = { if (!isArchived) recording = RecordTarget(it) },
                        )
                        OwnerTab.Members -> MembersTab(data)
                        OwnerTab.Schedule -> ScheduleSection(data, onPayOut = if (isArchived) null else ({ payingOut = it }))
                        OwnerTab.Payments -> PaymentsTab(data, onVoid = if (isArchived) null else ({ voiding = it }))
                    }
                }
            }
        }
    }
        if (current != null && !isArchived) {
            RecordButton(Modifier.align(Alignment.BottomEnd).padding(KSpace.xl)) { choosingAction = true }
        }
    }

    if (choosingAction) {
        KBottomSheet(title = stringResource(R.string.detail_record_payment), onDismiss = { choosingAction = false }) { close ->
            Column(Modifier.padding(horizontal = KSpace.xl).padding(bottom = KSpace.xl)) {
                if (canPayOutNow) {
                    ActionRow(KIcons.arrowUpRight, stringResource(R.string.detail_pay_out_s, monthName)) {
                        close()
                        payingOut = current?.monthIndex
                    }
                }
                ActionRow(KIcons.plus, stringResource(R.string.detail_record_one_payment)) {
                    close()
                    recording = RecordTarget(null)
                }
                ActionRow(KIcons.checklist, stringResource(R.string.detail_collect_s_tap_to_settle, monthName)) {
                    close()
                    collecting = true
                }
            }
        }
    }
    recording?.let { target -> RecordPaymentSheet(data, model, target.memberId) { recording = null } }
    if (collecting) CollectMonthSheet(data, model) { collecting = false }
    voiding?.let { target -> VoidSheet(target, model) { voiding = null } }
    payingOut?.let { month -> PayoutSheet(data, model, month) { payingOut = null } }
    if (reminding) RemindSheet(data.kameti, model.dependencies, onDismiss = { reminding = false })
}

/** Who a payment is being recorded for; `null` lets the owner choose. */
private class RecordTarget(val memberId: String?)

/** Pay out shows once every member has paid this month (and it isn't paid out yet). */
private fun canPayOut(data: KametiDetailData, row: MonthCollectionRow): Boolean =
    row.memberCount > 0 && row.paidCount >= row.memberCount && !isPaidOut(row.state) &&
        DetailLogic.recipients(data.kameti, row.monthIndex, data.slots, data.shares, data.members).isNotEmpty()

/** The floating "Record payment" action on every tab. */
@Composable
private fun RecordButton(modifier: Modifier = Modifier, onClick: () -> Unit) {
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
        KText(stringResource(R.string.detail_record_payment), KTextToken.bodyStrong, color = KColors.textOnBrand)
    }
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

/** Shown above an archived kameti's tabs: what archived means. */
@Composable
private fun ArchivedBanner(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(KColors.surfaceSunken, RoundedCornerShape(KRadius.card))
            .padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(KIcons.archiveFilled)
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            KText(stringResource(R.string.detail_archived), KTextToken.bodyStrong)
            KText(
                stringResource(R.string.detail_read_only_for_you_and_every_member),
                KTextToken.bodySm,
                color = KColors.textSecondary,
            )
        }
    }
}

// Overview

/**
 * This month's pot, who has paid, the recipients and every member's status
 * (board A · Kameti overview).
 */
@Composable
private fun OverviewTab(
    data: KametiDetailData,
    onRemind: (() -> Unit)?,
    /** Set while this month can be paid out. */
    onPayOut: (() -> Unit)?,
    onRecord: (String) -> Unit,
) {
    val current = data.current
    val summary = if (current == null) DetailLogic.finalSummary(data) else null
    when {
        current != null -> CurrentMonth(data, current, onRemind, onPayOut, onRecord)
        summary != null -> FinishedOverview(data, summary)
        else -> KMessageCard(
            title = stringResource(R.string.detail_not_started_yet),
            message = stringResource(R.string.detail_collections_begin_when_the_kameti_starts),
            icon = KIcons.hourglass,
        )
    }
}

@Composable
private fun CurrentMonth(
    data: KametiDetailData,
    current: MonthCollectionRow,
    onRemind: (() -> Unit)?,
    onPayOut: (() -> Unit)?,
    onRecord: (String) -> Unit,
) {
    val owing = DetailLogic.owing(data.months, current.monthIndex)
    val recipients = DetailLogic.recipients(data.kameti, current.monthIndex, data.slots, data.shares, data.members)
    val counts = DetailLogic.statusCounts(data.months, current.monthIndex)
    val rows = data.months.filter { it.monthIndex == current.monthIndex }
    val byId = data.members.associateBy { it.id }
    val toGo = current.target - current.received

    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CardLabel(
                    stringResource(R.string.detail_s_month_n, DetailLogic.monthTitle(current.monthStart), current.monthIndex),
                    Modifier.weight(1f),
                )
                CollectionStatePill(current.state)
            }
            // Received (cash this month) drives the pot and payout; covered
            // drives member statuses.
            KPotProgress(
                collected = current.received,
                target = current.target,
                caption = if (toGo.isPositive) {
                    stringResource(R.string.detail_collected_of_s_s_to_go, current.target.format(), toGo.format())
                } else {
                    stringResource(R.string.detail_collected_of_s, current.target.format())
                },
                headline = KPotHeadline.None,
                captionAboveBar = true,
            )
            KFlowRow {
                KStatusChip(KPaymentStatus.Paid, stringResource(R.string.detail_n_paid, counts.paid))
                KStatusChip(KPaymentStatus.Partial, stringResource(R.string.detail_n_partial, counts.partial))
                KStatusChip(KPaymentStatus.Unpaid, stringResource(R.string.detail_n_unpaid, counts.unpaid))
            }
            if (recipients.isNotEmpty()) {
                if (isPaidOut(current.state)) PaidOutStrip(data, current, recipients) else RecipientsBox(data, recipients)
            }
        }
    }

    if (owing.isNotEmpty() && onRemind != null) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 48.dp)
                .clip(CircleShape)
                .border(1.5.dp, KColors.brand, CircleShape)
                .clickable(role = Role.Button, onClick = onRemind),
            horizontalArrangement = Arrangement.spacedBy(KSpace.sm, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            KIcon(KIcons.bell, tint = KColors.brand)
            KText(
                stringResource(R.string.detail_remind_n_members_who_owe, owing.size),
                KTextToken.bodyStrong,
                color = KColors.brand,
            )
        }
    }

    Column {
        KSectionHeader(
            stringResource(R.string.detail_this_month),
            actionTitle = onPayOut?.let { stringResource(R.string.detail_pay_out_s, DetailLogic.monthName(current.monthStart)) },
            showsChevron = true,
            action = onPayOut,
        )
        rows.forEachIndexed { index, row ->
            val member = byId[row.memberId] ?: return@forEachIndexed
            MemberRow(
                // Someone who still owes: tap to record their payment.
                onClick = if (row.remaining.isPositive) ({ onRecord(member.id) }) else null,
                member = member,
                members = data.members,
                subtitle = if (row.status == MonthStatusCode.Advance) {
                    stringResource(R.string.detail_covered_by_credit)
                } else {
                    stringResource(R.string.detail_s_of_s, row.allocated.format(), row.due.format(symbol = false))
                },
                showsDivider = index < rows.size - 1,
            ) {
                StatusTextPill(row.status)
            }
        }
    }
}

@Composable
private fun recipientNames(data: KametiDetailData, recipients: List<DetailLogic.Recipient>): String {
    val you = stringResource(R.string.detail_you)
    return recipients.joinToString(" + ") { if (it.member.id == data.me?.id) you else it.member.name }
}

private fun people(data: KametiDetailData, recipients: List<DetailLogic.Recipient>): List<KPerson> =
    recipients.map { KPerson(it.member.name, DetailLogic.colorIndex(it.member, data.members)) }

@Composable
private fun PaidOutStrip(data: KametiDetailData, current: MonthCollectionRow, recipients: List<DetailLogic.Recipient>) {
    val short = current.state == MonthCollectionState.PaidOutShort && current.paidOutShortBy.isPositive
    val names = recipientNames(data, recipients)
    val slotIds = data.slots.filter { it.payoutMonthIndex == current.monthIndex }.map { it.id }.toSet()
    val paidOn = data.payouts.filter { it.voidedAt == null && it.slotId in slotIds }.maxOfOrNull { it.paidOn }
    KPaidOutStrip(
        people = people(data, recipients),
        title = if (short) {
            stringResource(R.string.detail_paid_out_s_short_s, current.paidOut.format(), current.paidOutShortBy.format())
        } else {
            stringResource(R.string.detail_paid_out_s, current.paidOut.format())
        },
        subtitle = if (paidOn != null) "$names · ${DetailLogic.dayMonth(paidOn)}" else names,
        isShort = short,
    )
}

@Composable
private fun RecipientsBox(data: KametiDetailData, recipients: List<DetailLogic.Recipient>) {
    val same = recipients.map { it.payout }.toSet().size == 1
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(KColors.surfaceSunken, RoundedCornerShape(KRadius.input))
            .padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KAvatarStack(people(data, recipients))
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            KText(recipientNames(data, recipients), KTextToken.bodyStrong)
            KText(
                when {
                    recipients.size == 1 -> stringResource(R.string.detail_receives_s, recipients[0].payout.format())
                    same -> stringResource(R.string.detail_s_each_shared_slot, recipients[0].payout.format())
                    else -> stringResource(R.string.detail_shared_slot)
                },
                KTextToken.subtitle,
                color = KColors.textSubtitle,
            )
        }
    }
}

/**
 * Overview once every month is over (§6.11 Completed): what was collected
 * and paid out in total, and who still owes or is owed.
 */
@Composable
private fun FinishedOverview(data: KametiDetailData, summary: DetailLogic.FinalSummary) {
    val byId = data.members.associateBy { it.id }
    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CardLabel(
                    "${DetailLogic.monthTitle(summary.firstMonth)} – ${DetailLogic.monthTitle(summary.lastMonth)}",
                    Modifier.weight(1f),
                )
                if (summary.isSettled) {
                    KPill(stringResource(R.string.detail_settled), KColors.positive, KColors.positiveSubtle)
                } else {
                    KPill(stringResource(R.string.detail_balances_open), KColors.warning, KColors.warningSubtle)
                }
            }
            KText(
                stringResource(
                    if (data.kameti.status == KametiStatus.Cancelled) R.string.detail_cancelled else R.string.detail_finished,
                ),
                KTextToken.titleLg,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.lg)) {
                Figure(stringResource(R.string.detail_collected), summary.collected.format(), Modifier.weight(1f))
                Figure(stringResource(R.string.detail_paid_out), summary.paidOut.format(), Modifier.weight(1f))
                Figure(
                    stringResource(R.string.detail_payouts),
                    stringResource(R.string.detail_s_of_s, summary.monthsPaidOut.toString(), summary.months.toString()),
                    Modifier.weight(1f),
                )
            }
        }
    }

    @Composable
    fun rows(title: String, items: List<MemberBalanceRow>, amount: (MemberBalanceRow) -> Money) {
        if (items.isEmpty()) return
        Column {
            KSectionHeader(title)
            items.forEachIndexed { index, row ->
                val member = byId[row.memberId] ?: return@forEachIndexed
                MemberRow(
                    member = member,
                    members = data.members,
                    subtitle = stringResource(
                        R.string.detail_paid_s_of_s,
                        row.totalPaid.format(),
                        row.dueToDate.format(symbol = false),
                    ),
                    showsDivider = index < items.size - 1,
                ) {
                    KMoneyText(amount(row), style = KMoneyStyle.Title)
                }
            }
        }
    }
    rows(stringResource(R.string.detail_still_owes), summary.owing) { it.owes }
    rows(stringResource(R.string.detail_is_owed_back), summary.credit) { it.credit }
}

// Members

/**
 * Members (board A v2 · Members): search, a heads-up for people who haven't
 * joined, and one row per member with slots, balance and join state.
 */
@Composable
private fun MembersTab(data: KametiDetailData) {
    if (data.members.isEmpty()) {
        KMessageCard(
            title = stringResource(R.string.detail_no_members_yet),
            message = stringResource(R.string.detail_members_you_add_will_show_here),
            icon = KIcons.people,
        )
        return
    }
    var search by rememberSaveable { mutableStateOf("") }
    val balances = data.balances.associateBy { it.memberId }
    val notJoined = data.members.count { it.joinStatus != JoinStatus.Joined && it.profileId == null }
    val list = data.members.filter { search.isBlank() || it.name.contains(search.trim(), ignoreCase = true) }

    KTextField(
        text = search,
        onTextChange = { search = it },
        placeholder = stringResource(R.string.detail_search_n_members, data.members.size),
        capitalization = KeyboardCapitalization.Words,
        leading = { KIcon(KIcons.search) },
    )

    if (notJoined > 0 && data.kameti.status != KametiStatus.Archived) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(KColors.warningSubtle, RoundedCornerShape(12.dp))
                .padding(KSpace.md),
            horizontalArrangement = Arrangement.spacedBy(KSpace.sm + 2.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            KIcon(KIcons.envelope, tint = KColors.warning)
            KText(
                if (notJoined == 1) {
                    stringResource(R.string.detail_1_person_hasnt_joined_the_app_yet)
                } else {
                    stringResource(R.string.detail_n_people_havent_joined_the_app_yet, notJoined)
                },
                KTextToken.bodySm,
                color = KColors.warning,
            )
        }
    }

    Column {
        list.forEachIndexed { index, member ->
            val balance = balances[member.id]
            val slots = DetailLogic.slotCount(member, data.shares)
            MemberRow(
                member = member,
                members = data.members,
                subtitle = when {
                    slots == 0 -> stringResource(R.string.detail_no_slot_yet)
                    balance == null -> null
                    slots == 1 -> stringResource(R.string.detail_1_slot_s_mo, balance.monthlyDue.format())
                    else -> stringResource(R.string.detail_n_slots_s_mo, slots, balance.monthlyDue.format())
                },
                showsDivider = index < list.size - 1,
            ) {
                Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    if (balance != null) BalanceChip(balance)
                    JoinCaption(member.joinStatus)
                }
            }
        }
    }
}

@Composable
private fun JoinCaption(status: JoinStatus) {
    val strong = KTextStyle(size = 12f, weight = FontWeight.SemiBold)
    when (status) {
        JoinStatus.Joined -> KText(stringResource(R.string.detail_joined), KTextToken.subtitleSmall, color = KColors.textSubtitle)
        JoinStatus.Invited -> KText(stringResource(R.string.detail_invited), strong, color = KColors.warning)
        JoinStatus.PendingApproval -> KText(stringResource(R.string.detail_needs_approval), strong, color = KColors.info)
        JoinStatus.NotInvited ->
            KText(stringResource(R.string.detail_not_invited), KTextToken.subtitleSmall, color = KColors.textSubtitle)
        JoinStatus.Declined -> KText(stringResource(R.string.detail_declined), KTextToken.caption, color = KColors.negative)
    }
}

// Payments

private data class MoneyEntry(
    val id: String,
    val date: LocalDate,
    val kind: PaymentKind,
    val title: String,
    val subtitle: String,
    val amount: Money,
    val isVoided: Boolean,
    val methodLabel: String,
)

/**
 * Payments (board A v2 · Payments): a month and Received / Paid out filter,
 * two summary cards, and the money list grouped by day.
 */
@Composable
private fun PaymentsTab(data: KametiDetailData, onVoid: ((VoidTarget) -> Unit)?) {
    val kameti = data.kameti
    var monthIndex by rememberSaveable { mutableStateOf<Int?>(null) }
    var kind by rememberSaveable { mutableStateOf(PaymentKind.Received) }
    var pickingMonth by remember { mutableStateOf(false) }
    val month = monthIndex ?: data.current?.monthIndex ?: DetailLogic.monthIndex(data.today, kameti) ?: 1
    val start = DetailLogic.monthStart(kameti, month)
    val payments = DetailLogic.newestFirst(data.payments.filter { DetailLogic.monthIndex(it.receivedOn, kameti) == month })
    val payouts = data.payouts.filter { DetailLogic.monthIndex(it.paidOn, kameti) == month }.sortedByDescending { it.paidOn }
    val row = data.collections.firstOrNull { it.monthIndex == month }
    val valid = payments.count { it.voidedAt == null }
    val owing = DetailLogic.owing(data.months, month).size
    val stillDue = row?.let { Money(maxOf(it.target.rupees - it.received.rupees, 0)) } ?: Money.ZERO
    val byId = data.members.associateBy { it.id }

    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
        Row(
            modifier = Modifier
                .height(36.dp)
                .clip(CircleShape)
                .background(KColors.surface)
                .border(1.dp, KColors.border, CircleShape)
                .clickable(role = Role.Button) { pickingMonth = true }
                .padding(horizontal = KSpace.md),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            KText(DetailLogic.monthTitle(start), KTextStyle(size = 13f, weight = FontWeight.SemiBold))
            KIcon(KIcons.chevronDown, tint = KColors.textPrimary, size = 16.dp)
        }
        FilterChip(stringResource(R.string.detail_received), kind == PaymentKind.Received) { kind = PaymentKind.Received }
        FilterChip(stringResource(R.string.detail_paid_out), kind == PaymentKind.PaidOut) { kind = PaymentKind.PaidOut }
    }

    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
        SummaryCard(
            stringResource(R.string.detail_received), row?.received ?: Money.ZERO,
            stringResource(R.string.detail_n_payments, valid), KMoneyTone.Neutral, Modifier.weight(1f),
        )
        SummaryCard(
            stringResource(R.string.detail_still_due), stillDue,
            stringResource(R.string.detail_n_members, owing), KMoneyTone.Negative, Modifier.weight(1f),
        )
    }

    val entries: List<MoneyEntry> = if (kind == PaymentKind.Received) {
        payments.map { payment ->
            val method = payment.method.label()
            MoneyEntry(
                id = payment.id, date = payment.receivedOn, kind = PaymentKind.Received,
                title = byId[payment.memberId]?.name.orEmpty(),
                subtitle = if (payment.voidedAt != null) {
                    stringResource(R.string.detail_voided_s, payment.voidReason.orEmpty())
                } else {
                    val paidBy = stringResource(R.string.detail_paid_by_s, payment.paidByName.orEmpty())
                    DetailLogic.paymentSubtitle(payment, method) { paidBy }
                },
                amount = payment.amount, isVoided = payment.voidedAt != null, methodLabel = method,
            )
        }
    } else {
        payouts.map { payout ->
            MoneyEntry(
                id = payout.id, date = payout.paidOn, kind = PaymentKind.PaidOut,
                title = byId[payout.memberId]?.name.orEmpty(),
                subtitle = if (payout.voidedAt != null) {
                    stringResource(R.string.detail_voided_s, payout.voidReason.orEmpty())
                } else {
                    listOfNotNull(payout.method.label(), payout.reference).filter { it.isNotEmpty() }.joinToString(" · ")
                },
                amount = payout.amount, isVoided = payout.voidedAt != null, methodLabel = payout.method.label(),
            )
        }
    }

    if (entries.isEmpty()) {
        KMessageCard(
            title = stringResource(
                if (kind == PaymentKind.Received) R.string.detail_no_payments_yet else R.string.detail_no_payouts_yet,
            ),
            message = stringResource(R.string.detail_nothing_recorded_in_s, DetailLogic.monthTitle(start)),
            icon = KIcons.receipt,
        )
    } else {
        Column {
            // Already newest first, so one pass groups the days in order.
            val days = entries.map { it.date }.distinct()
            for (day in days) {
                val group = entries.filter { it.date == day }
                CardLabel(
                    if (day == data.today) {
                        stringResource(R.string.detail_today_s, DetailLogic.dayMonth(day))
                    } else {
                        DetailLogic.dayMonth(day)
                    },
                    Modifier.padding(top = KSpace.md, bottom = 2.dp),
                )
                group.forEachIndexed { index, entry ->
                    // Tap an entry to void it (a voided one stays as it is).
                    val tap = if (onVoid != null && !entry.isVoided) {
                        Modifier.clickable(role = Role.Button) {
                            onVoid(
                                VoidTarget(
                                    entry.id, entry.title, entry.amount,
                                    "${DetailLogic.dayMonth(entry.date)} · ${entry.methodLabel}",
                                    isPayout = entry.kind == PaymentKind.PaidOut,
                                ),
                            )
                        }
                    } else {
                        Modifier
                    }
                    Box(tap) {
                        PaymentRow(
                            kind = entry.kind, title = entry.title, subtitle = entry.subtitle, amount = entry.amount,
                            isVoided = entry.isVoided, showsDivider = index < group.size - 1,
                        )
                    }
                }
            }
        }
    }

    if (pickingMonth) {
        val months = (1..maxOf(kameti.monthsN, 1)).map { DetailLogic.monthStart(kameti, it) }
        KBottomSheet(title = DetailLogic.monthTitle(start), onDismiss = { pickingMonth = false }) { close ->
            KMonthGrid(start, months, runLength = null, modifier = Modifier.weight(1f, fill = false)) { picked ->
                monthIndex = months.indexOf(picked) + 1
                close()
            }
        }
    }
}

@Composable
private fun FilterChip(title: String, isOn: Boolean, onClick: () -> Unit) {
    KText(
        title,
        KTextStyle(size = 13f, weight = if (isOn) FontWeight.SemiBold else FontWeight.Medium),
        modifier = Modifier
            .clip(CircleShape)
            .background(if (isOn) KColors.brandSubtle else KColors.surface)
            .border(1.dp, if (isOn) KColors.brand else KColors.border, CircleShape)
            .clickable(role = Role.Tab, onClick = onClick)
            .semantics { selected = isOn }
            .padding(horizontal = KSpace.md, vertical = 9.dp),
        color = if (isOn) KColors.onBrandSubtle else KColors.textPrimary,
    )
}

@Composable
private fun SummaryCard(title: String, amount: Money, note: String, tone: KMoneyTone, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(14.dp)
    Column(
        modifier = modifier.background(KColors.surface, shape).border(1.dp, KColors.border, shape).padding(KSpace.md),
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        KText(title, KTextToken.subtitleSmall, color = KColors.textSubtitle)
        KMoneyText(amount, style = KMoneyStyle.Title, tone = tone)
        KText(note, KTextToken.subtitleSmall, color = KColors.textSubtitle)
    }
}
