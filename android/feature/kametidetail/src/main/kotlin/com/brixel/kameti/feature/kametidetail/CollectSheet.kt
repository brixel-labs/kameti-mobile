package com.brixel.kameti.feature.kametidetail

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KChipStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConnectivity
import com.brixel.kameti.ui.KFlowRow
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KOfflineActionBanner
import com.brixel.kameti.ui.KPotProgress
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTonalButton
import com.brixel.kameti.ui.KTonalStyle
import com.brixel.kameti.ui.kDismissesKeyboard
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import kotlinx.coroutines.launch

/**
 * "Collect November" (board A v2 · Record many, option 3, tap to settle): tap a
 * person to mark what they owe, hold to edit the amount, then save them all
 * together with one date and method.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun CollectMonthSheet(data: KametiDetailData, model: KametiDetailViewModel, onDismiss: () -> Unit) {
    val opened = remember { data }
    var session by remember { mutableStateOf(CollectSession.of(opened)) }
    // One key per member, made once, so a retry never records twice.
    val keys = remember { session.lines.associate { it.memberId to model.idempotencyKey() } }
    var editing by remember { mutableStateOf<String?>(null) }
    var receivedOn by remember { mutableStateOf(opened.today) }
    var method by remember { mutableStateOf(PaymentMethod.Cash) }
    var reference by remember { mutableStateOf("") }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    val scope = rememberCoroutineScope()
    val haptics = LocalHapticFeedback.current
    val byId = remember { opened.members.associateBy { it.id } }
    val monthName = opened.current?.let { DetailLogic.monthName(it.monthStart) }.orEmpty()
    val online = KConnectivity.isOnline

    KBottomSheet(
        title = stringResource(R.string.detail_collect_s_kameti, monthName), onDismiss = onDismiss, expanded = true,
        dismissDisabled = isBusy,
    ) { close ->
        LazyColumn(
            modifier = Modifier.weight(1f).padding(horizontal = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                    opened.current?.let { KPotProgress(it.received, it.target, marked = session.total) }
                    KText(
                        stringResource(R.string.detail_lighter_bar_marked_in_this_session_not_saved),
                        KTextToken.subtitleSmall,
                        color = KColors.textSubtitle,
                    )
                }
            }
            if (session.lines.isEmpty()) {
                item {
                    KMessageCard(
                        title = stringResource(R.string.detail_everyone_has_paid),
                        message = stringResource(R.string.detail_nobody_owes_anything_for_this_month),
                        icon = KIcons.checkCircle,
                    )
                }
            } else {
                // Only while someone is left to pay.
                item {
                    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                        CardLabel(stringResource(R.string.detail_tap_to_mark_the_full_amount_hold_to), Modifier.weight(1f))
                        KTonalButton(
                            stringResource(if (session.allMarked) R.string.detail_clear_all else R.string.detail_mark_all_paid),
                            onClick = { session = session.markAll() },
                            style = KTonalStyle.Neutral,
                        )
                    }
                }
            }
            items(session.lines, key = { it.memberId }) { line ->
                val member = byId[line.memberId] ?: return@items
                val state = session.state(line.memberId)
                val shape = RoundedCornerShape(14.dp)
                val (fill, border) = when (state) {
                    CollectSession.RowState.Unmarked -> KColors.surface to KColors.border
                    is CollectSession.RowState.Settled -> KColors.positiveSubtle to KColors.positive.copy(alpha = 0.35f)
                    is CollectSession.RowState.Partial -> KColors.warningSubtle to KColors.warning.copy(alpha = 0.4f)
                }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(shape)
                        .background(fill)
                        .border(1.dp, border, shape)
                        .combinedClickable(
                            role = Role.Button,
                            onClick = { session = session.toggle(line.memberId) },
                            onLongClick = {
                                haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                                editing = line.memberId
                            },
                        )
                        .padding(horizontal = KSpace.md, vertical = KSpace.sm + 2.dp),
                    horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    KAvatar(member.name, DetailLogic.colorIndex(member, opened.members))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        KText(member.name, KTextToken.bodyStrong)
                        when (state) {
                            CollectSession.RowState.Unmarked -> KText(
                                stringResource(R.string.detail_owes_s, line.remaining.format(symbol = false)),
                                KTextToken.subtitleSmall, color = KColors.textSubtitle,
                            )
                            is CollectSession.RowState.Settled -> KText(
                                stringResource(R.string.detail_s_settled, state.amount.format()),
                                KTextToken.subtitleSmall, color = KColors.positive,
                            )
                            is CollectSession.RowState.Partial -> KText(
                                stringResource(
                                    R.string.detail_s_still_owes_s, state.amount.format(), state.stillOwes.format(symbol = false),
                                ),
                                KTextToken.subtitleSmall, color = KColors.warning,
                            )
                        }
                    }
                    when (state) {
                        CollectSession.RowState.Unmarked -> RowPill(
                            stringResource(R.string.detail_mark_s, line.remaining.formatCompact()),
                            null, KColors.brand, KColors.brand, KColors.surface,
                        )
                        is CollectSession.RowState.Settled -> RowPill(
                            stringResource(R.string.detail_paid), KIcons.check, KColors.textOnBrand, KColors.brand, KColors.brand,
                        )
                        is CollectSession.RowState.Partial -> RowPill(
                            stringResource(R.string.detail_edit), null, KColors.warning, KColors.warning, KColors.surface,
                        )
                    }
                }
            }
            item { Column(Modifier.height(KSpace.xs)) {} }
        }

        Column(
            Modifier.background(KColors.background).padding(horizontal = KSpace.xl, vertical = KSpace.md),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            DateMethodBar(
                prefix = stringResource(R.string.detail_received),
                date = receivedOn, onDateChange = { receivedOn = it },
                method = method, onMethodChange = { method = it },
                reference = reference, onReferenceChange = { reference = it },
                today = opened.today, earliest = opened.kameti.startMonth,
            )
            FailureLine(failure)
            if (!online) KOfflineActionBanner(stringResource(R.string.detail_cant_record_payments_offline_connect_and_try_again))
            KButton(
                if (session.count == 1) {
                    stringResource(R.string.detail_save_1_payment_s, session.total.format())
                } else {
                    stringResource(R.string.detail_save_n_payments_s, session.count, session.total.format())
                },
                onClick = {
                    val ref = reference.trim()
                    var items = session.items(keys)
                    if (method == PaymentMethod.BankTransfer && ref.isNotEmpty()) items = items.map { it.copy(reference = ref) }
                    isBusy = true
                    failure = null
                    scope.launch {
                        val result = model.recordPayments(items, receivedOn, method)
                        isBusy = false
                        if (result != null) {
                            failure = result
                        } else {
                            close()
                            model.offerReceipts(items.map { PendingReceipt(it.memberId, it.amount, receivedOn) })
                        }
                    }
                },
                enabled = session.count > 0 && online,
                isLoading = isBusy,
            )
        }
    }

    editing?.let { id ->
        val line = session.lines.firstOrNull { it.memberId == id }
        val member = byId[id]
        if (line != null && member != null) {
            EditAmountSheet(member, line, session.marked[id], onDismiss = { editing = null }) { amount ->
                session = session.set(id, amount)
            }
        }
    }
}

@Composable
private fun RowPill(title: String, icon: ImageVector?, foreground: Color, border: Color, fill: Color) {
    Row(
        modifier = Modifier
            .height(40.dp)
            .background(fill, CircleShape)
            .border(1.dp, border, CircleShape)
            .padding(horizontal = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) KIcon(icon, tint = foreground, size = 14.dp)
        KText(title, KTextStyle(size = 13f, weight = FontWeight.SemiBold), color = foreground, maxLines = 1)
    }
}

/** Hold a person to set a different amount: their owed amount is one tap. */
@Composable
private fun EditAmountSheet(
    member: Member,
    line: CollectSession.Line,
    current: Money?,
    onDismiss: () -> Unit,
    onSet: (Money) -> Unit,
) {
    var digits by remember { mutableStateOf((current ?: line.remaining).rupees.toString()) }
    val amount = Money.parse(digits) ?: Money.ZERO
    val half = Money(line.remaining.rupees / 2 / 1_000 * 1_000)

    KBottomSheet(title = stringResource(R.string.detail_amount), onDismiss = onDismiss) { close ->
        Column(
            Modifier
                .weight(1f, fill = false)
                .verticalScroll(rememberScrollState())
                .kDismissesKeyboard()
                .padding(horizontal = KSpace.xl)
                .padding(bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            FieldLabel(stringResource(R.string.detail_how_much_did_s_pay, member.name))
            AmountBox(digits, { digits = it })
            KFlowRow {
                KChip(
                    stringResource(R.string.detail_owes_s, line.remaining.format(symbol = false)),
                    amount == line.remaining,
                    onClick = { digits = line.remaining.rupees.toString() },
                    style = KChipStyle.Outlined,
                )
                if (line.remaining.rupees >= 2_000) {
                    KChip(
                        stringResource(R.string.detail_half_s, half.format(symbol = false)),
                        amount == half,
                        onClick = { digits = half.rupees.toString() },
                        style = KChipStyle.Outlined,
                    )
                }
            }
            KButton(
                if (amount.isPositive) stringResource(R.string.detail_mark_s, amount.format()) else stringResource(R.string.detail_clear),
                onClick = {
                    onSet(amount)
                    close()
                },
            )
        }
    }
}
