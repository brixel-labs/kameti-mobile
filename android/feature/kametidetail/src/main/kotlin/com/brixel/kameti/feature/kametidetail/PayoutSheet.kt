package com.brixel.kameti.feature.kametidetail

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.ui.KAmountInput
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KCheckbox
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KChipStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConnectivity
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KMoneyStyle
import com.brixel.kameti.ui.KMoneyText
import com.brixel.kameti.ui.KOfflineActionBanner
import com.brixel.kameti.ui.KPotHeadline
import com.brixel.kameti.ui.KPotProgress
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.kDismissesKeyboard
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import kotlinx.coroutines.launch

/**
 * "Pay out November" (board AF · Record payout; FR-51 to FR-53, E20 to E23):
 * who receives the pot, how much each, any dues taken from a payout, and the
 * shortfall when the month wasn't fully collected.
 */
@Composable
internal fun PayoutSheet(data: KametiDetailData, model: KametiDetailViewModel, monthIndex: Int, onDismiss: () -> Unit) {
    val opened = remember { data }
    val row = remember { opened.collections.firstOrNull { it.monthIndex == monthIndex } }
    var draft by remember {
        mutableStateOf(
            PayoutDraft(
                PayoutLogic.recipients(
                    opened.kameti, monthIndex, opened.members, opened.slots, opened.shares, opened.payouts,
                    opened.balances, row?.payoutShortfall ?: Money.ZERO,
                ),
            ),
        )
    }
    // Made once, so a retry never records anything twice.
    val payoutKeys = remember { draft.recipients.associate { it.id to model.idempotencyKey() } }
    val deductionKeys = remember { draft.recipients.associate { it.id to model.idempotencyKey() } }
    var paidOn by remember { mutableStateOf(opened.today) }
    var method by remember { mutableStateOf(PaymentMethod.Cash) }
    var reference by remember { mutableStateOf("") }
    var note by remember { mutableStateOf("") }
    var showNoteError by remember { mutableStateOf(false) }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    // The recipient whose amount is being typed (Custom).
    var customId by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val focus = LocalFocusManager.current
    val monthName = DetailLogic.monthName(DetailLogic.monthStart(opened.kameti, monthIndex))
    val online = KConnectivity.isOnline

    /** Picks a preset total, keeping any dues deduction on. */
    fun choose(recipient: PayoutRecipient, target: Money) {
        focus.clearFocus()
        customId = null
        val had = draft.deduction(recipient.id) != null
        var next = if (had) draft.setDeduction(recipient.id, false) else draft
        next = next.set(recipient.id, target)
        draft = if (had) next.setDeduction(recipient.id, true) else next
    }

    KBottomSheet(
        title = stringResource(R.string.detail_pay_out_s_kameti, monthName), onDismiss = onDismiss, expanded = true,
        dismissDisabled = isBusy,
    ) { close ->
        Column(
            Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .kDismissesKeyboard()
                .padding(horizontal = KSpace.xl)
                .padding(bottom = KSpace.lg),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            if (row != null) Summary(row)
            if (row != null && row.payoutShortfall.isPositive) {
                ShortfallBanner(row, DetailLogic.owing(opened.months, monthIndex).size)
            }
            if (draft.recipients.isEmpty()) {
                KMessageCard(
                    title = stringResource(R.string.detail_no_one_to_pay_out),
                    message = stringResource(R.string.detail_this_months_slot_has_no_one_in_it),
                    icon = KIcons.personOff,
                )
            }
            for (recipient in draft.recipients) {
                RecipientCard(
                    recipient = recipient,
                    draft = draft,
                    isMe = recipient.member.id == opened.me?.id,
                    isTyping = customId == recipient.id,
                    onChoose = { choose(recipient, it) },
                    onCustom = { customId = recipient.id },
                    onAmount = { draft = draft.set(recipient.id, it) },
                    onDeduction = { draft = draft.setDeduction(recipient.id, it) },
                )
            }
            if (draft.recipients.isNotEmpty()) {
                KText(
                    stringResource(R.string.detail_the_shortfall_is_split_by_share_change_the),
                    KTextToken.subtitleSmall,
                    color = KColors.textSubtitle,
                )
            }
            if (draft.needsNote) {
                val missing = showNoteError && note.isBlank()
                val hint = stringResource(R.string.detail_an_amount_that_differs_from_what_is_expected)
                KTextField(
                    note, { note = it },
                    title = stringResource(R.string.detail_note),
                    placeholder = stringResource(R.string.detail_why_does_it_differ_e_g_hassan_covered),
                    error = hint.takeIf { missing },
                    helper = hint,
                )
            }
        }

        Column(
            Modifier.background(KColors.background).padding(horizontal = KSpace.xl, vertical = KSpace.md),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            DateMethodBar(
                prefix = stringResource(R.string.detail_paid),
                date = paidOn, onDateChange = { paidOn = it },
                method = method, onMethodChange = { method = it },
                reference = reference, onReferenceChange = { reference = it },
                today = opened.today, earliest = opened.kameti.startMonth,
            )
            FailureLine(failure)
            if (!online) KOfflineActionBanner(stringResource(R.string.detail_cant_record_a_payout_offline_connect_and_try))
            KButton(
                stringResource(R.string.detail_mark_paid_out_s, draft.total.format()),
                onClick = {
                    val trimmed = note.trim()
                    if (draft.needsNote && trimmed.isEmpty()) {
                        showNoteError = true
                        return@KButton
                    }
                    val ref = reference.trim()
                    val entries = draft.recipients.map {
                        KametiDetailViewModel.PayoutEntry(it.slotId, it.id, draft.amount(it.id), draft.deduction(it.id))
                    }
                    isBusy = true
                    failure = null
                    scope.launch {
                        val result = model.recordPayouts(
                            entries, paidOn, method,
                            reference = ref.takeIf { method == PaymentMethod.BankTransfer && it.isNotEmpty() },
                            note = trimmed.ifEmpty { null },
                            deductionNote = context.getString(R.string.detail_taken_from_the_month_n_payout, monthIndex),
                            payoutKeys = payoutKeys, deductionKeys = deductionKeys,
                        )
                        isBusy = false
                        if (result != null) failure = result else close()
                    }
                },
                enabled = draft.hasAnything && online,
                isLoading = isBusy,
            )
        }
    }
}

@Composable
private fun Summary(row: MonthCollectionRow) {
    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                KText(stringResource(R.string.detail_collected), KTextToken.body, Modifier.weight(1f), KColors.textSecondary)
                KMoneyText(row.received, style = KMoneyStyle.Title)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                KText(stringResource(R.string.detail_full_pot), KTextToken.body, Modifier.weight(1f), KColors.textSecondary)
                KMoneyText(row.target)
            }
            KPotProgress(row.received, row.target, headline = KPotHeadline.None)
        }
    }
}

@Composable
private fun ShortfallBanner(row: MonthCollectionRow, owing: Int) {
    val text = buildAnnotatedString {
        withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) {
            append(stringResource(R.string.detail_s_short, row.payoutShortfall.format()))
        }
        append(
            if (owing == 1) {
                stringResource(R.string.detail_one_member_still_owes_it_you_can_pay)
            } else {
                stringResource(R.string.detail_n_members_still_owe_it_you_can_pay, owing)
            },
        )
    }
    Row(
        modifier = Modifier.fillMaxWidth().background(KColors.warningSubtle, RoundedCornerShape(12.dp)).padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm + 2.dp),
    ) {
        KIcon(KIcons.error, tint = KColors.warning)
        KText(text, KTextToken.bodySm, color = KColors.warning)
    }
}

@Composable
private fun RecipientCard(
    recipient: PayoutRecipient,
    draft: PayoutDraft,
    isMe: Boolean,
    isTyping: Boolean,
    onChoose: (Money) -> Unit,
    onCustom: () -> Unit,
    onAmount: (Money) -> Unit,
    onDeduction: (Boolean) -> Unit,
) {
    val amount = draft.amount(recipient.id)
    val deduction = draft.deduction(recipient.id)
    val total = amount + (deduction ?: Money.ZERO)
    val isPlanned = total == recipient.suggested
    val isFull = total == recipient.outstanding
    val isCustom = isTyping || (!isPlanned && !isFull)
    val shape = RoundedCornerShape(14.dp)
    val focusRequester = remember { FocusRequester() }

    Column(
        modifier = Modifier.fillMaxWidth().background(KColors.surface, shape).border(1.dp, KColors.border, shape).padding(KSpace.md),
        verticalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md), verticalAlignment = Alignment.CenterVertically) {
            KAvatar(recipient.member.name, recipient.colorIndex)
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                KText(if (isMe) stringResource(R.string.detail_you) else recipient.member.name, KTextToken.bodyStrong)
                KText(
                    stringResource(R.string.detail_expected_s, recipient.outstanding.format()),
                    KTextToken.subtitleSmall,
                    color = KColors.textSubtitle,
                )
            }
        }
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
            // The big amount: plain text, or editable in place (with "Rs" kept) once Custom is chosen.
            Box(Modifier.heightIn(min = 40.dp), contentAlignment = Alignment.Center) {
                if (isTyping) {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                        KText("Rs", KTextStyle(size = 24f, weight = FontWeight.Bold), color = KColors.textSecondary)
                        KAmountInput(
                            if (amount.isZero) "" else amount.rupees.toString(),
                            { onAmount(Money.parse(it) ?: Money.ZERO) },
                            Modifier.widthIn(max = 200.dp).focusRequester(focusRequester),
                            style = KTextStyle(size = 28f, weight = FontWeight.Bold, tabular = true),
                        )
                    }
                    LaunchedEffect(Unit) { focusRequester.requestFocus() }
                } else {
                    KMoneyText(
                        amount,
                        Modifier.clickable(
                            indication = null, interactionSource = remember { MutableInteractionSource() }, onClick = onCustom,
                        ),
                        style = KMoneyStyle.Display,
                    )
                }
            }
            KText(stringResource(R.string.detail_paying_now), KTextToken.subtitleSmall, color = KColors.textSubtitle)
        }
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(KSpace.sm, Alignment.CenterHorizontally),
        ) {
            // "Planned" (less this person's part of the shortfall) only differs from
            // "Full" when the month was collected short.
            if (recipient.suggested != recipient.outstanding) {
                KChip(
                    stringResource(R.string.detail_planned), isPlanned && !isTyping,
                    onClick = { onChoose(recipient.suggested) }, style = KChipStyle.Outlined,
                )
            }
            KChip(
                stringResource(R.string.detail_full), isFull && !isTyping,
                onClick = { onChoose(recipient.outstanding) }, style = KChipStyle.Outlined,
            )
            KChip(stringResource(R.string.detail_custom), isCustom, onClick = onCustom, icon = KIcons.edit, style = KChipStyle.Outlined)
        }
        if (recipient.owes.isPositive) {
            val name = firstName(recipient.member.name)
            KCheckbox(
                isOn = deduction != null,
                onChange = onDeduction,
                modifier = Modifier.fillMaxWidth().background(KColors.background, RoundedCornerShape(10.dp)).padding(KSpace.sm + 2.dp),
            ) {
                KText(
                    if (deduction != null) {
                        stringResource(R.string.detail_s_is_taken_from_s_s_payout_and, deduction.format(), name)
                    } else {
                        stringResource(R.string.detail_s_owes_s_take_it_from_the_payout, name, recipient.owes.format())
                    },
                    KTextToken.bodySm,
                )
            }
        }
    }
}
