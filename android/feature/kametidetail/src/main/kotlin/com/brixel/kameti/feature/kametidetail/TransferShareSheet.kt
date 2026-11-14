package com.brixel.kameti.feature.kametidetail

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.Share
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KChipStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KFlowRow
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMonthField
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.kDismissesKeyboard
import kotlinx.coroutines.launch

/**
 * Transfer a member's share (board AT-1): pick the share, who takes it over
 * and from which month, with an optional settlement note and a live summary.
 */
@Composable
internal fun TransferShareSheet(data: KametiDetailData, model: KametiDetailViewModel, member: Member, onDismiss: () -> Unit) {
    // The sheet works on the data it opened with, so a reload under it changes nothing mid-entry.
    val opened = remember { data }
    val shares = remember { TransferLogic.movableShares(member, opened) }
    val scope = rememberCoroutineScope()
    var shareId by remember { mutableStateOf(shares.firstOrNull()?.id.orEmpty()) }
    var targetId by remember { mutableStateOf<String?>(null) }
    var addingNew by remember { mutableStateOf(false) }
    var newName by remember { mutableStateOf("") }
    var fromMonth by remember {
        val month = shares.firstOrNull()?.let { TransferLogic.firstMonth(it, opened) } ?: 1
        mutableStateOf(DetailLogic.monthStart(opened.kameti, month))
    }
    var note by remember { mutableStateOf("") }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }

    val share = shares.firstOrNull { it.id == shareId }
    val first = firstName(member.name)
    val fromIndex = DetailLogic.monthIndex(fromMonth, opened.kameti) ?: 1
    val targetName = if (addingNew) {
        newName.trim().takeIf { MemberLogic.isValidName(newName) }
    } else {
        opened.members.firstOrNull { it.id == targetId }?.name
    }
    val allowedMonths = share?.let { TransferLogic.firstMonth(it, opened) }
        ?.let { firstAllowed -> (firstAllowed..opened.kameti.monthsN).map { DetailLogic.monthStart(opened.kameti, it) } }
        .orEmpty()

    KBottomSheet(
        stringResource(R.string.detail_transfer_s_s_share, first), onDismiss, expanded = true, dismissDisabled = isBusy,
    ) { close ->
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).kDismissesKeyboard()
                .padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            if (share == null) {
                KText(stringResource(R.string.detail_s_has_no_share_that_can_move, first), KTextToken.body, color = KColors.textSecondary)
                return@Column
            }
            val payout = TransferLogic.payoutMonth(share, opened)
            val payoutStart = DetailLogic.monthStart(opened.kameti, payout)

            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                FieldLabel(stringResource(R.string.detail_share))
                if (shares.size > 1) {
                    KFlowRow {
                        shares.forEach { item ->
                            KChip(
                                stringResource(R.string.detail_slot_n_s, TransferLogic.payoutMonth(item, opened), item.monthlyAmount.format()),
                                isOn = item.id == shareId,
                                onClick = {
                                    shareId = item.id
                                    targetId = null
                                    // Never earlier than this share can move.
                                    val firstAllowed = TransferLogic.firstMonth(item, opened)
                                    if (firstAllowed != null && fromIndex < firstAllowed) {
                                        fromMonth = DetailLogic.monthStart(opened.kameti, firstAllowed)
                                    }
                                },
                                style = KChipStyle.Outlined,
                            )
                        }
                    }
                }
                val shape = RoundedCornerShape(12.dp)
                Column(
                    Modifier.fillMaxWidth().background(KColors.surface, shape).border(1.dp, KColors.brand, shape).padding(KSpace.md),
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    KText(stringResource(R.string.detail_slot_n_paid_out_s, payout, DetailLogic.monthTitle(payoutStart)), KTextToken.bodyStrong)
                    KText(stringResource(R.string.detail_s_a_month, share.monthlyAmount.format()), KTextToken.bodySm, color = KColors.textSecondary)
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                FieldLabel(stringResource(R.string.detail_goes_to))
                KFlowRow {
                    TransferLogic.candidates(share, opened).forEach { person ->
                        KChip(
                            person.name, isOn = !addingNew && targetId == person.id,
                            onClick = { addingNew = false; targetId = person.id }, style = KChipStyle.Outlined,
                        )
                    }
                    KChip(
                        stringResource(R.string.detail_someone_new), isOn = addingNew,
                        onClick = { addingNew = true; targetId = null }, icon = KIcons.plus, style = KChipStyle.Outlined,
                    )
                }
                if (addingNew) {
                    KTextField(
                        newName, { newName = it }, placeholder = stringResource(R.string.detail_their_name),
                        capitalization = KeyboardCapitalization.Words,
                    )
                }
            }

            KMonthField(stringResource(R.string.detail_from), fromMonth, allowedMonths, { fromMonth = it })
            KTextField(
                note, { note = it }, title = stringResource(R.string.detail_settlement_note_optional),
                placeholder = stringResource(R.string.detail_e_g_sara_pays_ali_back_rs_2), lines = 2,
            )

            // What changes, in words.
            val who = targetName?.let(::firstName) ?: stringResource(R.string.detail_the_new_holder)
            val fromTitle = DetailLogic.monthTitle(fromMonth)
            val payoutName = DetailLogic.monthName(payoutStart)
            val amount = share.monthlyAmount.format()
            Column(
                Modifier.fillMaxWidth().background(KColors.brandSubtle, RoundedCornerShape(14.dp)).padding(KSpace.md + 2.dp),
                verticalArrangement = Arrangement.spacedBy(KSpace.sm),
            ) {
                KText(stringResource(R.string.detail_what_changes), KTextToken.bodyStrong, color = KColors.brand)
                KText(
                    if (payout >= fromIndex) {
                        stringResource(R.string.detail_from_s_s_pays_s_a_month_and, fromTitle, who, amount, payoutName)
                    } else {
                        stringResource(R.string.detail_from_s_s_pays_s_a_month_the, fromTitle, who, amount, payoutName, first)
                    },
                    KTextToken.body,
                )
                KText(
                    if (fromIndex > share.effectiveFromMonth) {
                        stringResource(
                            R.string.detail_s_keeps_the_s_paid_so_far_and, first, TransferLogic.paidSoFar(member, opened).format(),
                            DetailLogic.monthTitle(DetailLogic.monthStart(opened.kameti, fromIndex - 1)),
                        )
                    } else {
                        stringResource(R.string.detail_nothing_has_been_due_on_this_share_yet)
                    },
                    KTextToken.bodySm, color = KColors.textSecondary,
                )
            }
            FailureLine(failure)
            KButton(
                targetName?.let { stringResource(R.string.detail_transfer_to_s, firstName(it)) }
                    ?: stringResource(R.string.detail_transfer_share),
                onClick = {
                    val target = if (addingNew) {
                        newName.trim().takeIf { MemberLogic.isValidName(newName) }?.let { KametiDetailViewModel.TransferTarget.NewPerson(it) }
                    } else {
                        targetId?.let { KametiDetailViewModel.TransferTarget.Existing(it) }
                    }
                    if (target != null) {
                        isBusy = true
                        failure = null
                        scope.launch {
                            val result = model.transferShare(share.id, target, fromIndex, note)
                            isBusy = false
                            if (result != null) failure = result else close()
                        }
                    }
                },
                enabled = targetName != null, isLoading = isBusy,
            )
        }
    }
}
