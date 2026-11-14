package com.brixel.kameti.feature.kametidetail

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KButtonStyle
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KChipStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConnectivity
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KFlowRow
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMoneyStyle
import com.brixel.kameti.ui.KMoneyText
import com.brixel.kameti.ui.KOfflineActionBanner
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.kDismissesKeyboard
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import kotlinx.coroutines.launch

/**
 * Record payment (board A · Record payment): who paid, how much, when and how.
 * The amount can be filled with what is left or the full month.
 */
@Composable
internal fun RecordPaymentSheet(
    data: KametiDetailData,
    model: KametiDetailViewModel,
    preselected: String?,
    onDismiss: () -> Unit,
) {
    // The sheet works on the data it opened with, so a reload under it changes nothing mid-entry.
    val opened = remember { data }
    val first = remember {
        preselected ?: PaymentLogic.payers(opened)
            .firstOrNull { PaymentLogic.monthRow(it.id, opened)?.remaining?.isPositive == true }?.id
    }
    fun owed(id: String?): String =
        id?.let { PaymentLogic.monthRow(it, opened)?.remaining }?.takeIf { it.isPositive }?.rupees?.toString().orEmpty()

    var memberId by remember { mutableStateOf(first) }
    var digits by remember { mutableStateOf(owed(first)) }
    var dateChoice by remember { mutableStateOf(DateChoice.Today) }
    var customDate by remember { mutableStateOf(opened.today) }
    var method by remember { mutableStateOf(PaymentMethod.Cash) }
    var reference by remember { mutableStateOf("") }
    var note by remember { mutableStateOf("") }
    var pickingMember by remember { mutableStateOf(false) }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    // Made once, so a retry never records twice.
    val key = remember { model.idempotencyKey() }
    val scope = rememberCoroutineScope()
    val focus = LocalFocusManager.current

    val member = opened.members.firstOrNull { it.id == memberId }
    val row = memberId?.let { PaymentLogic.monthRow(it, opened) }
    val amount = Money.parse(digits) ?: Money.ZERO
    val monthName = opened.current?.let { DetailLogic.monthName(it.monthStart) }.orEmpty()
    val online = KConnectivity.isOnline

    KBottomSheet(
        title = stringResource(R.string.detail_record_payment), onDismiss = onDismiss, expanded = true,
        dismissDisabled = isBusy,
    ) { close ->
        Column(
            Modifier
                .weight(1f, fill = false)
                .verticalScroll(rememberScrollState())
                .kDismissesKeyboard()
                .padding(horizontal = KSpace.xl)
                .padding(bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                FieldLabel(stringResource(R.string.detail_member))
                val shape = RoundedCornerShape(12.dp)
                // The whole card is the button, not just the arrow.
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(shape)
                        .border(1.dp, KColors.border, shape)
                        .clickable(role = Role.Button) {
                            focus.clearFocus()
                            pickingMember = true
                        }
                        .padding(horizontal = KSpace.md, vertical = KSpace.sm + 2.dp),
                    horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    if (member != null) {
                        KAvatar(member.name, DetailLogic.colorIndex(member, opened.members))
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            KText(member.name, KTextToken.bodyStrong)
                            if (row != null) {
                                KText(
                                    stringResource(R.string.detail_due_s_paid_s, row.due.format(), row.allocated.format()),
                                    KTextToken.subtitleSmall,
                                    color = KColors.textSubtitle,
                                )
                            }
                        }
                    } else {
                        KText(
                            stringResource(R.string.detail_choose_a_member), KTextToken.body,
                            modifier = Modifier.weight(1f), color = KColors.textSecondary,
                        )
                    }
                    KIcon(KIcons.chevronDown, size = 18.dp)
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                FieldLabel(stringResource(R.string.detail_amount_received))
                AmountBox(digits, { digits = it })
                if (row != null && row.due.isPositive) {
                    // Quick amounts from this member's month: what they still owe
                    // (only when they have paid part of it) and the full month.
                    KFlowRow {
                        if (row.remaining.isPositive && row.remaining != row.due) {
                            KChip(
                                stringResource(R.string.detail_remaining_s, row.remaining.format(symbol = false)),
                                amount == row.remaining,
                                onClick = { digits = row.remaining.rupees.toString() },
                                style = KChipStyle.Outlined,
                            )
                        }
                        KChip(
                            stringResource(R.string.detail_full_month_s, row.due.format(symbol = false)),
                            amount == row.due,
                            onClick = { digits = row.due.rupees.toString() },
                            style = KChipStyle.Outlined,
                        )
                    }
                }
            }

            ReceivedDateChooser(dateChoice, customDate, opened.today, opened.kameti.startMonth) { choice, custom ->
                dateChoice = choice
                customDate = custom
            }
            MethodChooser(method, { method = it }, reference, { reference = it })
            KTextField(
                note, { note = it },
                title = stringResource(R.string.detail_note_optional),
                placeholder = stringResource(R.string.detail_e_g_meezan_transfer_ref_88213),
            )

            val name = member?.let { firstName(it.name) }.orEmpty()
            when (val outcome = PaymentLogic.outcome(amount, row)) {
                PaymentOutcome.None -> Unit
                PaymentOutcome.FullyPaid -> NoteBanner(
                    stringResource(R.string.detail_s_will_be_fully_paid_for_s, name, monthName),
                    KIcons.check, KColors.positive, KColors.positiveSubtle,
                )
                is PaymentOutcome.StillOwes -> NoteBanner(
                    stringResource(R.string.detail_s_will_still_owe_s_for_s, name, outcome.amount.format(), monthName),
                    KIcons.clock, KColors.warning, KColors.warningSubtle,
                )
                is PaymentOutcome.Credit -> NoteBanner(
                    stringResource(R.string.detail_s_extra_becomes_credit_for_later_months, outcome.amount.format()),
                    KIcons.plusCircle, KColors.info, KColors.infoSubtle,
                )
            }
            FailureLine(failure)
            if (!online) KOfflineActionBanner(stringResource(R.string.detail_cant_record_payments_offline_connect_and_try_again))
            KButton(
                stringResource(R.string.detail_record_s, amount.format()),
                onClick = {
                    val id = memberId ?: return@KButton
                    if (!amount.isPositive) return@KButton
                    isBusy = true
                    failure = null
                    val ref = reference.trim()
                    scope.launch {
                        val result = model.recordPayment(
                            memberId = id, amount = amount, receivedOn = dateChoice.date(opened.today, customDate),
                            method = method,
                            reference = ref.takeIf { method == PaymentMethod.BankTransfer && it.isNotEmpty() },
                            note = note.trim().ifEmpty { null }, idempotencyKey = key,
                        )
                        isBusy = false
                        if (result != null) {
                            failure = result
                        } else {
                            close()
                            model.offerReceipts(listOf(PendingReceipt(id, amount, dateChoice.date(opened.today, customDate))))
                        }
                    }
                },
                enabled = amount.isPositive && memberId != null && online,
                isLoading = isBusy,
            )
        }
    }

    if (pickingMember) {
        KBottomSheet(title = stringResource(R.string.detail_choose_a_member), onDismiss = { pickingMember = false }) { close ->
            MemberPickerList(opened, memberId, Modifier.weight(1f, fill = false)) { id ->
                memberId = id
                owed(id).takeIf { it.isNotEmpty() }?.let { digits = it }
                close()
            }
        }
    }
}

/** The members to pick from, with what each still owes this month. */
@Composable
internal fun MemberPickerList(data: KametiDetailData, selected: String?, modifier: Modifier = Modifier, onPick: (String) -> Unit) {
    LazyColumn(modifier) {
        items(PaymentLogic.payers(data), key = { it.id }) { member ->
            val row = PaymentLogic.monthRow(member.id, data)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(role = Role.Button) { onPick(member.id) }
                    .padding(horizontal = KSpace.xl, vertical = KSpace.sm + 2.dp),
                horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                KAvatar(member.name, DetailLogic.colorIndex(member, data.members))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                    KText(member.name, KTextToken.bodyStrong)
                    if (row != null) {
                        val owes = row.remaining.isPositive
                        KText(
                            if (owes) {
                                stringResource(R.string.detail_owes_s, row.remaining.format())
                            } else {
                                stringResource(R.string.detail_paid_up)
                            },
                            KTextToken.caption,
                            color = if (owes) KColors.negative else KColors.positive,
                        )
                    }
                }
                if (member.id == selected) KIcon(KIcons.check, tint = KColors.brand)
            }
            KDivider(Modifier.padding(start = KSpace.xl))
        }
    }
}

/** What is being voided: a payment or a payout. */
internal data class VoidTarget(
    val id: String,
    val name: String,
    val amount: Money,
    val subtitle: String,
    val isPayout: Boolean,
)

/**
 * Void a payment or payout: entries are never edited or deleted, so a mistake
 * is voided with a reason and entered again.
 */
@Composable
internal fun VoidSheet(target: VoidTarget, model: KametiDetailViewModel, onDismiss: () -> Unit) {
    var reason by remember { mutableStateOf("") }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    val scope = rememberCoroutineScope()
    val title = stringResource(if (target.isPayout) R.string.detail_void_payout else R.string.detail_void_payment)

    KBottomSheet(title = title, onDismiss = onDismiss, dismissDisabled = isBusy) { close ->
        Column(
            Modifier
                .weight(1f, fill = false)
                .verticalScroll(rememberScrollState())
                .kDismissesKeyboard()
                .padding(horizontal = KSpace.xl)
                .padding(bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            KCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        KText(target.name, KTextToken.bodyStrong)
                        KText(target.subtitle, KTextToken.subtitleSmall, color = KColors.textSubtitle)
                    }
                    KMoneyText(target.amount, style = KMoneyStyle.Title)
                }
            }
            KTextField(
                reason, { reason = it },
                title = stringResource(R.string.detail_why_is_this_being_voided),
                placeholder = stringResource(R.string.detail_e_g_entered_for_the_wrong_member),
            )
            KText(
                stringResource(R.string.detail_it_stays_in_the_history_struck_through_and),
                KTextToken.bodySm,
                color = KColors.textSubtitle,
            )
            FailureLine(failure)
            KButton(
                title,
                onClick = {
                    isBusy = true
                    failure = null
                    val trimmed = reason.trim()
                    scope.launch {
                        val result = if (target.isPayout) {
                            model.voidPayout(target.id, trimmed)
                        } else {
                            model.voidPayment(target.id, trimmed)
                        }
                        isBusy = false
                        if (result != null) failure = result else close()
                    }
                },
                style = KButtonStyle.Destructive,
                enabled = reason.isNotBlank(),
                isLoading = isBusy,
            )
        }
    }
}
