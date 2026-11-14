package com.brixel.kameti.feature.createkameti

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.ShareInput
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KAvatarSize
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDates
import com.brixel.kameti.ui.KFlowRow
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMoneyStyle
import com.brixel.kameti.ui.KMoneyText
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KSpinner
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTonalButton
import com.brixel.kameti.ui.KTonalStyle
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import java.time.LocalDate

/** Step 4 (AC-4): fill every slot, whole or split between up to three people. */
@Composable
internal fun SlotsStep(state: WizardState, model: CreateWizardViewModel) {
    val checks = state.checks
    val slots = state.slots.sortedBy { it.payoutMonthIndex }
    val amount = state.slotAmount ?: Money.ZERO
    val ready = slots.size - checks.emptySlots.size - checks.badSlots.size
    val byId = state.members.associateBy { it.id }
    // The slot shown in the sheet stays while the sheet slides away.
    var sheetSlot by remember { mutableStateOf<Slot?>(null) }
    LaunchedEffect(state.editingSlotId) {
        state.slots.firstOrNull { it.id == state.editingSlotId }?.let { sheetSlot = it }
    }

    Column(Modifier.fillMaxSize()) {
        StepBody(Modifier.weight(1f)) {
            WizardHeading(
                stringResource(R.string.create_fill_the_n_slots, slots.size),
                stringResource(R.string.create_each_slot_is_s_a_month_give_it, amount.format(), state.pot.format()),
            )
            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                Row {
                    KText(stringResource(R.string.create_slots_ready), KTextToken.body, modifier = Modifier.weight(1f), color = KColors.textSecondary)
                    KText(stringResource(R.string.create_n_of_n, ready, slots.size), KTextToken.bodyStrong.copy(tabular = true))
                }
                Box(Modifier.fillMaxWidth().height(6.dp).background(KColors.border, CircleShape)) {
                    val fraction = if (slots.isEmpty()) 0f else ready.toFloat() / slots.size
                    Box(Modifier.fillMaxWidth(fraction).fillMaxHeight().background(KColors.brand, CircleShape))
                }
            }
            if (checks.unassigned.isNotEmpty()) {
                val names = listAnd(checks.unassigned.map { it.name })
                Row(
                    Modifier.fillMaxWidth().background(KColors.warningSubtle, RoundedCornerShape(KRadius.input)).padding(KSpace.md),
                    horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
                ) {
                    KIcon(KIcons.error, tint = KColors.warning, size = 18.dp)
                    KText(
                        stringResource(
                            if (checks.unassigned.size == 1) R.string.create_s_isnt_in_any_slot_yet else R.string.create_s_arent_in_any_slot_yet,
                            names,
                        ),
                        KTextToken.bodySm, color = KColors.warning,
                    )
                }
                // A slot of their own: one more month, same monthly amount, bigger pot.
                if (state.canAddSlot) {
                    val shape = RoundedCornerShape(KRadius.input)
                    Row(
                        Modifier.fillMaxWidth().clip(shape).background(KColors.surface).border(1.dp, KColors.border, shape)
                            .clickable(enabled = !state.isBusy, role = Role.Button) { model.launch { addSlot() } }
                            .padding(KSpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
                    ) {
                        KIcon(KIcons.plusCircleFilled, tint = KColors.brand, size = 22.dp)
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            KText(stringResource(R.string.create_add_a_slot), KTextToken.bodyStrong, color = KColors.brand)
                            KText(
                                stringResource(R.string.create_n_months_pot_becomes_s, state.months + 1, (amount * (state.months + 1)).format()),
                                KTextToken.bodySm, color = KColors.textSecondary,
                            )
                        }
                        if (state.isBusy) KSpinner(size = 18.dp)
                    }
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                slots.forEach { slot ->
                    val date = addingMonths(slot.payoutMonthIndex - 1, state.startMonth)
                    // A year label above the first slot of each year.
                    if (slot.payoutMonthIndex == 1 || date.year != date.minusMonths(1).year) {
                        KText("${date.year}", KTextToken.label, color = KColors.textSecondary, modifier = Modifier.padding(top = KSpace.sm))
                    }
                    SlotRow(slot, date, amount, byId, state) { model.editSlot(slot.id) }
                }
            }
        }
        WizardFooter(
            stringResource(R.string.create_next_payout_order), action = { model.goTo(WizardStep.Order) },
            isEnabled = checks.slotsFilled && checks.slotsAddUp, onBack = { model.back() },
        )
    }

    sheetSlot?.let { slot ->
        val month = addingMonths(slot.payoutMonthIndex - 1, state.startMonth)
        KBottomSheet(
            title = stringResource(R.string.create_slot_n_s, slot.payoutMonthIndex, KDates.monthLabel(month)),
            onDismiss = { sheetSlot = null; model.editSlot(null) },
            expanded = true,
            dismissDisabled = state.isBusy,
        ) { close ->
            // Saved (or emptied): the model closed the editor, so slide the sheet away. Not while
            // the save is still reloading: the sheet refuses to close until the write is done.
            LaunchedEffect(state.editingSlotId, state.isBusy) { if (state.editingSlotId == null && !state.isBusy) close() }
            SlotSplitEditor(state, model, slot, month)
        }
    }
}

/** One slot: its number, who is in it and a status mark (design AC-4). The whole row opens it. */
@Composable
private fun SlotRow(slot: Slot, date: LocalDate, amount: Money, byId: Map<String, Member>, state: WizardState, onClick: () -> Unit) {
    val active = PlanChecks.activeShares(slot.id, state.shares)
    val amounts = active.map { it.monthlyAmount }
    val valid = PlanChecks.isValidSplit(amounts, amount)
    val partial = active.isNotEmpty() && !valid
    val shape = RoundedCornerShape(KRadius.card)
    Row(
        Modifier.fillMaxWidth().height(IntrinsicSize.Min).clip(shape).background(KColors.surface)
            .border(if (partial) 2.dp else 1.dp, if (partial) KColors.warning else KColors.border, shape)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(KSpace.md),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        Column(Modifier.width(48.dp), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            KText(KDates.monthName(date), KTextToken.bodyStrong, color = if (partial) KColors.warning else KColors.textPrimary, maxLines = 1)
            KText(stringResource(R.string.create_slot_n, slot.payoutMonthIndex), KTextToken.subtitleSmall, color = KColors.textSubtitle, maxLines = 1)
        }
        Box(Modifier.width(1.dp).fillMaxHeight().padding(vertical = 2.dp).background(KColors.border))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            KText(
                if (active.isEmpty()) stringResource(R.string.create_empty) else active.joinToString(" + ") { byId[it.memberId]?.name ?: "" },
                KTextToken.bodyStrong, maxLines = 1,
            )
            when {
                active.isEmpty() -> KText(stringResource(R.string.create_tap_to_add_people), KTextToken.subtitle, color = KColors.textSubtitle)
                partial -> KText(
                    stringResource(R.string.create_s_still_to_assign, PlanChecks.remaining(amounts, amount).format()),
                    KTextToken.bodySm, color = KColors.warning,
                )
                active.size == 1 -> KText(
                    stringResource(R.string.create_whole_slot_s, amount.format()), KTextToken.subtitle, color = KColors.textSubtitle,
                )
                else -> KText(
                    amounts.joinToString(" + ") { it.format(symbol = false) }, KTextToken.subtitle, color = KColors.textSubtitle, maxLines = 1,
                )
            }
        }
        when {
            valid -> KIcon(KIcons.checkCircleFilled, tint = KColors.positive, size = 24.dp)
            active.isEmpty() -> KIcon(KIcons.plus, tint = KColors.brand)
            else -> KIcon(KIcons.chevronRight, tint = if (partial) KColors.warning else KColors.textTertiary)
        }
    }
}

/**
 * The split editor for one slot (design AC-4 final): a progress card, the
 * chosen people with amount controls, and everyone else to add. Splitting is
 * optional: one person gets the whole slot.
 */
@Composable
private fun ColumnScope.SlotSplitEditor(state: WizardState, model: CreateWizardViewModel, slot: Slot, month: LocalDate) {
    val saved = remember(slot.id) { PlanChecks.activeShares(slot.id, state.shares) }
    var split by remember(slot.id) {
        mutableStateOf(SlotSplit(state.slotAmount ?: Money.ZERO, saved.map { SlotSplit.Line(it.memberId, it.monthlyAmount) }))
    }
    var activeId by remember(slot.id) { mutableStateOf(saved.firstOrNull()?.memberId) }
    val byId = state.members.associateBy { it.id }
    val segmentColors = listOf(KColors.warning, KColors.brand, KColors.info, KColors.onBrandSubtle)
    val remaining = split.remaining
    val monthName = KDates.monthLabel(month).substringBefore(" ")

    // Fills what the sheet has left under its title, so the footer stays on screen.
    Column(Modifier.weight(1f).fillMaxWidth()) {
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = KSpace.xl).padding(bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            WizardHeading(
                stringResource(R.string.create_who_pays_what_each_month),
                stringResource(R.string.create_this_slot_needs_s_a_month_up_to, split.total.format()),
            )
            SplitProgress(split, remaining, segmentColors) { split = split.splitEvenly() }
            split.lines.forEach { line ->
                val member = byId[line.id] ?: return@forEach
                PersonCard(
                    member = member, line = line, split = split, state = state, monthName = monthName,
                    isOpen = split.lines.size == 1 || activeId == line.id,
                    onOpen = { activeId = line.id },
                    onRemove = {
                        split = split.remove(member.id)
                        if (activeId == member.id) activeId = split.lines.firstOrNull()?.id
                    },
                    onChange = { split = it },
                )
            }
            if (split.canAdd) {
                AddSection(split, state, slot) { member ->
                    split = split.add(member.id)
                    activeId = member.id
                }
            }
        }
        WizardFooter(
            primaryTitle = when {
                split.lines.isEmpty() -> stringResource(R.string.create_add_someone)
                split.isValid -> stringResource(R.string.create_save_slot)
                split.hasUnset -> stringResource(R.string.create_set_an_amount)
                remaining.isNegative -> stringResource(R.string.create_over_by_s, (-remaining).format())
                else -> stringResource(R.string.create_s_left, remaining.format())
            },
            action = {
                model.launch { saveSlotShares(slot.id, split.lines.map { ShareInput(it.id, it.amount) }) }
            },
            isEnabled = split.isValid,
            isLoading = state.isBusy,
            // A slot that already has people can be emptied.
            onBack = if (saved.isNotEmpty()) ({ model.launch { saveSlotShares(slot.id, emptyList()) } }) else null,
            backTitle = stringResource(R.string.create_empty_slot),
            backIsDestructive = true,
        )
    }
}

@Composable
private fun SplitProgress(split: SlotSplit, remaining: Money, colors: List<Color>, onSplitEvenly: () -> Unit) {
    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
            Row {
                KText(stringResource(R.string.create_assigned), KTextToken.body, modifier = Modifier.weight(1f), color = KColors.textSecondary)
                KText(stringResource(R.string.create_s_of_s, split.assigned.format(), split.total.format()), KTextToken.bodyStrong)
            }
            // One coloured segment per person, as wide as their share of the slot.
            Row(
                Modifier.fillMaxWidth().height(10.dp).clip(CircleShape).background(KColors.border),
                horizontalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                split.lines.forEachIndexed { index, line ->
                    if (line.amount.isPositive) {
                        Box(
                            Modifier.weight(line.amount.rupees.toFloat()).fillMaxHeight()
                                .background(colors[index % colors.size], RoundedCornerShape(3.dp)),
                        )
                    }
                }
                if (remaining.isPositive) Spacer(Modifier.weight(remaining.rupees.toFloat()))
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.xs)) {
                    when {
                        split.lines.isEmpty() -> KText(stringResource(R.string.create_add_someone_below), KTextToken.bodyStrong, color = KColors.textSecondary)
                        split.hasUnset -> KText(stringResource(R.string.create_set_an_amount_for_everyone), KTextToken.bodyStrong, color = KColors.warning)
                        remaining.isZero -> {
                            KIcon(KIcons.checkCircle, tint = KColors.positive, size = 18.dp)
                            KText(stringResource(R.string.create_adds_up), KTextToken.bodyStrong, color = KColors.positive)
                        }
                        remaining.isNegative -> KText(
                            stringResource(R.string.create_over_by_s, (-remaining).format()), KTextToken.bodyStrong, color = KColors.negative,
                        )
                        else -> KText(
                            stringResource(R.string.create_s_left_to_assign, remaining.format()), KTextToken.bodyStrong, color = KColors.warning,
                        )
                    }
                }
                if (split.lines.size > 1) {
                    KTonalButton(stringResource(R.string.create_split_evenly), onSplitEvenly, style = KTonalStyle.Neutral)
                }
            }
        }
    }
}

@Composable
private fun PersonCard(
    member: Member,
    line: SlotSplit.Line,
    split: SlotSplit,
    state: WizardState,
    monthName: String,
    isOpen: Boolean,
    onOpen: () -> Unit,
    onRemove: () -> Unit,
    onChange: (SlotSplit) -> Unit,
) {
    val payout = line.amount * state.months
    val shape = RoundedCornerShape(KRadius.card)

    @Composable
    fun identity(size: KAvatarSize, modifier: Modifier) {
        Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
            KAvatar(member.name, colorIndex(member, state.members), size = size)
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                KText(
                    if (member.profileId != null) stringResource(R.string.create_you_s, member.name) else member.name,
                    KTextToken.bodyStrong, maxLines = 1,
                )
                KText(
                    stringResource(R.string.create_gets_s_in_s, payout.format(), monthName),
                    KTextToken.subtitleSmall, color = KColors.textSubtitle, maxLines = 1,
                )
            }
        }
    }

    @Composable
    fun trash() {
        RoundIcon(
            KIcons.trash, stringResource(R.string.create_remove_s_from_this_slot, member.name),
            KColors.negative, KColors.negativeSubtle, 36, onRemove,
        )
    }

    if (isOpen) {
        Column(
            Modifier.fillMaxWidth().background(KColors.surface, shape).border(2.dp, KColors.textPrimary, shape).padding(KSpace.lg),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                identity(KAvatarSize.Large, Modifier.weight(1f))
                trash()
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                RoundIcon(KIcons.minus, stringResource(R.string.create_less), KColors.onBrandSubtle, KColors.brandSubtle, 48) {
                    onChange(split.nudge(line.id, -1))
                }
                Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    KMoneyText(line.amount, style = KMoneyStyle.Display)
                    KText(
                        if (line.amount.rupees < SlotSplit.UNIT) {
                            stringResource(R.string.create_pick_an_amount)
                        } else {
                            stringResource(R.string.create_a_month_steps_of_s, Money(SlotSplit.step(split.total)).formatCompact())
                        },
                        KTextToken.subtitleSmall, color = KColors.textSubtitle,
                    )
                }
                RoundIcon(KIcons.plus, stringResource(R.string.create_more), KColors.onBrandSubtle, KColors.brandSubtle, 48) {
                    onChange(split.nudge(line.id, 1))
                }
            }
            KFlowRow {
                split.options(line.id).forEach { preset ->
                    KChip(preset.formatCompact(), isOn = line.amount == preset, onClick = { onChange(split.set(line.id, preset)) })
                }
            }
        }
    } else {
        // Closed: the whole card opens it.
        Row(
            Modifier.fillMaxWidth().clip(shape).background(KColors.surface).border(1.dp, KColors.border, shape)
                .clickable(role = Role.Button, onClick = onOpen)
                .padding(horizontal = KSpace.md, vertical = KSpace.sm + 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            identity(KAvatarSize.Medium, Modifier.weight(1f))
            KMoneyText(line.amount, style = KMoneyStyle.Title)
            trash()
        }
    }
}

@Composable
private fun RoundIcon(icon: ImageVector, label: String, tint: Color, background: Color, size: Int, onClick: () -> Unit) {
    Box(
        Modifier.size(size.dp).clip(CircleShape).background(background).clickable(role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        KIcon(icon, tint = tint, size = (size * 0.45f).dp, label = label)
    }
}

@Composable
private fun AddSection(split: SlotSplit, state: WizardState, slot: Slot, onAdd: (Member) -> Unit) {
    val candidates = state.members.filter { member -> split.lines.none { it.id == member.id } }
    Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            KText(stringResource(R.string.create_add_someone).uppercase(), KTextToken.label, modifier = Modifier.weight(1f), color = KColors.textSecondary)
            KText(
                stringResource(R.string.create_n_of_n_spots_used, split.lines.size, SlotSplit.MAX_PEOPLE),
                KTextToken.subtitleSmall, color = KColors.textSubtitle,
            )
        }
        if (candidates.isEmpty()) {
            KText(stringResource(R.string.create_everyone_is_already_in_this_slot_add_more), KTextToken.subtitle, color = KColors.textSubtitle)
        } else {
            KFlowRow {
                candidates.forEach { member ->
                    // Slots this person already holds, not counting this one.
                    val count = state.shares
                        .filter { it.memberId == member.id && it.slotId != slot.id && it.effectiveToMonth == null }
                        .map { it.slotId }.toSet().size
                    val atLimit = count >= state.maxSlotsPerMember
                    Row(
                        Modifier.alpha(if (atLimit) 0.5f else 1f).clip(CircleShape).background(KColors.surface)
                            .border(1.dp, KColors.border, CircleShape)
                            .clickable(enabled = !atLimit, role = Role.Button) { onAdd(member) }
                            .padding(start = KSpace.xs, end = KSpace.md, top = KSpace.xs, bottom = KSpace.xs),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
                    ) {
                        KAvatar(member.name, colorIndex(member, state.members), size = KAvatarSize.Small)
                        Column {
                            KText(
                                if (member.profileId != null) stringResource(R.string.create_you) else member.name,
                                KTextToken.bodyStrong, maxLines = 1,
                            )
                            if (atLimit) {
                                KText(stringResource(R.string.create_in_n_slots_limit, count), KTextToken.caption, color = KColors.warning)
                            }
                        }
                        if (!atLimit) KIcon(KIcons.plus, tint = KColors.brand, size = 18.dp)
                    }
                }
            }
        }
    }
}
