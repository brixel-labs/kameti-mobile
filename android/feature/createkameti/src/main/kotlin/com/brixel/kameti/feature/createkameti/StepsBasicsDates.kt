package com.brixel.kameti.feature.createkameti

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Money
import com.brixel.kameti.ui.KAmountField
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KChipStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KCompactStepper
import com.brixel.kameti.ui.KDates
import com.brixel.kameti.ui.KDayTile
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KFlowRow
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMonthField
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KSize
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KStepper
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KToggle
import com.brixel.kameti.ui.fieldHeight
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.textSubtitle

private val suggestions = listOf<Long>(50_000, 100_000, 200_000, 250_000, 500_000)
private val quickDays = listOf(5, 10, 15)

/** The scrolling body of a step, above its footer. */
@Composable
internal fun StepBody(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Column(
        modifier.verticalScroll(rememberScrollState()).padding(KSpace.xl),
        verticalArrangement = Arrangement.spacedBy(KSpace.lg),
    ) { content() }
}

/**
 * Step 1 (AC-1): name, slot amount, months, first month and a live
 * "What this means" summary. Next creates or updates the draft.
 */
@Composable
internal fun BasicsStep(state: WizardState, model: CreateWizardViewModel) {
    // Errors show only after the first Next tap.
    var submitted by rememberSaveable { mutableStateOf(false) }
    // A year back to two years ahead, always including the chosen month.
    val startOptions = remember(state.startMonth) {
        val current = model.currentMonth
        ((-12..24).map { addingMonths(it, current) } + state.startMonth).distinct().sorted()
    }
    val lastMonth = addingMonths(state.months - 1, state.startMonth)

    Column(Modifier.fillMaxSize()) {
        StepBody(Modifier.weight(1f)) {
            WizardHeading(
                stringResource(R.string.create_the_basics),
                stringResource(R.string.create_you_can_change_these_until_you_start_the),
            )
            KTextField(
                state.name, model::setName,
                title = stringResource(R.string.create_kameti_name),
                placeholder = stringResource(R.string.create_e_g_office_kameti_2026),
                error = if (submitted && !state.nameValid) stringResource(R.string.create_use_3_to_40_characters) else null,
                helper = stringResource(R.string.create_members_see_this_name),
                capitalization = KeyboardCapitalization.Words,
            )
            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                KAmountField(
                    stringResource(R.string.create_each_slot_pays_per_month), state.amountText, model::setAmountText,
                    placeholder = "2,50,000",
                    error = if (submitted && !state.slotAmountValid) {
                        stringResource(R.string.create_enter_an_amount_in_steps_of_rs_1)
                    } else {
                        null
                    },
                )
                KFlowRow {
                    suggestions.forEach { value ->
                        KChip(Money(value).formatCompact(), isOn = state.amountText == "$value", onClick = { model.setAmountText("$value") })
                    }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md), verticalAlignment = Alignment.Top) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(KSpace.xs)) {
                    WizardLabel(stringResource(R.string.create_months_slots))
                    KStepper(
                        state.months, WizardLimits.MIN_MONTHS..WizardLimits.MAX_MONTHS,
                        stringResource(R.string.create_fewer_months), stringResource(R.string.create_more_months),
                        onChange = model::setMonths,
                    )
                }
                KMonthField(
                    stringResource(R.string.create_first_month), state.startMonth, startOptions, model::setStartMonth,
                    modifier = Modifier.weight(1f), runLength = state.months,
                )
            }
            KCard {
                Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                    KText(stringResource(R.string.create_what_this_means).uppercase(), KTextToken.label, color = KColors.textSecondary)
                    KeyValueRow(stringResource(R.string.create_pot_each_month), state.pot.format(), emphasis = true)
                    KeyValueRow(stringResource(R.string.create_one_full_slot_pays_in_total), state.pot.format())
                    KeyValueRow(
                        stringResource(R.string.create_runs),
                        "${KDates.shortMonthLabel(state.startMonth)} → ${KDates.shortMonthLabel(lastMonth)}",
                    )
                }
            }
        }
        WizardFooter(
            stringResource(R.string.create_next_due_date),
            action = {
                submitted = true
                if (state.nameValid && state.slotAmountValid) model.launch { saveBasics() }
            },
            isLoading = state.isBusy,
        )
    }
}

/** Step 2 (AC-2): due day, reminder days and the most slots per person. */
@Composable
internal fun DatesStep(state: WizardState, model: CreateWizardViewModel) {
    var otherOpen by remember { mutableStateOf(false) }
    // The overdue nudge and the owner summary are shown as in the design; the
    // backend has no fields for them yet, so they are not saved.
    var overdueReminder by rememberSaveable { mutableStateOf(true) }
    var ownerSummary by rememberSaveable { mutableStateOf(true) }

    Column(Modifier.fillMaxSize()) {
        StepBody(Modifier.weight(1f)) {
            WizardHeading(
                stringResource(R.string.create_due_date_and_reminders),
                stringResource(R.string.create_well_nudge_members_who_havent_paid_paid_members),
            )
            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                WizardLabel(stringResource(R.string.create_members_pay_by))
                KFlowRow {
                    quickDays.forEach { day ->
                        KChip(ordinal(day), isOn = state.dueDay == day, onClick = { model.setDueDay(day) }, style = KChipStyle.Outlined)
                    }
                    val custom = state.dueDay !in quickDays
                    KChip(
                        if (custom) ordinal(state.dueDay) else stringResource(R.string.create_other),
                        isOn = custom, onClick = { otherOpen = true }, style = KChipStyle.Outlined,
                    )
                }
            }
            Reminders(state, model)
            KCard {
                ToggleRow(
                    stringResource(R.string.create_overdue_reminder), stringResource(R.string.create_day_after_the_due_date),
                    overdueReminder,
                ) { overdueReminder = it }
                KDivider(Modifier.padding(vertical = KSpace.md))
                ToggleRow(
                    stringResource(R.string.create_tell_me_who_hasnt_paid),
                    stringResource(R.string.create_a_summary_for_you_on_the_s, ordinal(minOf(state.dueDay + 1, 28))),
                    ownerSummary,
                ) { ownerSummary = it }
                KDivider(Modifier.padding(vertical = KSpace.md))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        KText(stringResource(R.string.create_most_slots_per_person), KTextToken.bodyStrong)
                        KText(
                            stringResource(R.string.create_up_to_n, WizardLimits.MAX_SLOTS_PER_MEMBER),
                            KTextToken.subtitle, color = KColors.textSubtitle,
                        )
                    }
                    KCompactStepper(
                        state.maxSlotsPerMember, 1..WizardLimits.MAX_SLOTS_PER_MEMBER,
                        stringResource(R.string.create_fewer_slots_per_person), stringResource(R.string.create_more_slots_per_person),
                        onChange = model::setMaxSlots,
                    )
                }
            }
            ReminderPreview(state)
        }
        WizardFooter(
            stringResource(R.string.create_next_members), action = { model.launch { saveDates() } },
            isLoading = state.isBusy, onBack = { model.back() },
        )
    }

    if (otherOpen) {
        KBottomSheet(stringResource(R.string.create_pick_the_due_day), onDismiss = { otherOpen = false }) { close ->
            val list = rememberLazyListState(initialFirstVisibleItemIndex = maxOf(state.dueDay - 4, 0))
            LazyColumn(state = list, modifier = Modifier.fillMaxWidth()) {
                items(WizardLimits.dueDays.toList()) { day ->
                    Row(
                        Modifier.fillMaxWidth()
                            .clickable { model.setDueDay(day); close() }
                            .padding(horizontal = KSpace.xl, vertical = KSpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        KText(ordinal(day), KTextToken.body, modifier = Modifier.weight(1f))
                        if (state.dueDay == day) KIcon(KIcons.check, tint = KColors.brand)
                    }
                    KDivider(Modifier.padding(start = KSpace.xl))
                }
            }
        }
    }
}

@Composable
private fun Reminders(state: WizardState, model: CreateWizardViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
        WizardLabel(stringResource(R.string.create_remind_on_these_days_tap_to_change))
        // Five day tiles a row, up to the due day.
        (1..state.dueDay).chunked(5).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                row.forEach { day ->
                    val label = stringResource(R.string.create_remind_on_day_n, day)
                    KDayTile(
                        "$day", isOn = day in state.reminderDays, onClick = { model.toggleReminder(day) },
                        modifier = Modifier.weight(1f).semantics { contentDescription = label },
                    )
                }
                repeat(5 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
        val shape = RoundedCornerShape(KRadius.input)
        Row(
            Modifier.fillMaxWidth().heightIn(min = KSize.fieldHeight)
                .background(KColors.surface, shape).border(1.dp, KColors.border, shape)
                .padding(horizontal = KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            KText(stringResource(R.string.create_at), KTextToken.body, modifier = Modifier.weight(1f), color = KColors.textSecondary)
            KText(stringResource(R.string.create_10_00_am_pakistan_time), KTextToken.bodyStrong)
        }
    }
}

@Composable
private fun ToggleRow(title: String, subtitle: String, isOn: Boolean, onChange: (Boolean) -> Unit) {
    KToggle(isOn, onChange) {
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            KText(title, KTextToken.bodyStrong)
            KText(subtitle, KTextToken.subtitle, color = KColors.textSubtitle)
        }
    }
}

/** What a member's reminder will look like. */
@Composable
private fun ReminderPreview(state: WizardState) {
    val amount = (state.slotAmount ?: Money.ZERO).format()
    val month = KDates.monthLabel(state.startMonth).substringBefore(" ")
    val owner = state.ownerName ?: stringResource(R.string.create_your_kameti_owner)
    Row(
        Modifier.fillMaxWidth().background(KColors.surfaceSunken, RoundedCornerShape(KRadius.card)).padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        Box(
            Modifier.size(36.dp).background(KColors.brand, RoundedCornerShape(10.dp)).clearAndSetSemantics {},
            contentAlignment = Alignment.Center,
        ) {
            KText(stringResource(R.string.create_k), KTextToken.bodyStrong, color = KColors.textOnBrand)
        }
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            KText(state.name.ifEmpty { stringResource(R.string.create_your_kameti) }, KTextToken.bodyStrong)
            KText(
                stringResource(R.string.create_reminder_s_for_s_is_due_by_the, amount, month, ordinal(state.dueDay), owner),
                KTextToken.body,
            )
        }
    }
}
