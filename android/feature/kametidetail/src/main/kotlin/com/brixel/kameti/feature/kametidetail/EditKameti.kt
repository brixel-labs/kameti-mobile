package com.brixel.kameti.feature.kametidetail

import androidx.compose.foundation.background
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
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiChanges
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KChipStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDayTile
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KFlowRow
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.kDismissesKeyboard
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlinx.coroutines.launch

/**
 * What the owner can change on a running kameti, and the rules for it
 * (FR-10, FR-34): name, description, due day and reminder days. The slot
 * amount, months, start month and slot limit are fixed once it starts.
 * Each change returns a new form.
 */
internal data class EditKametiForm(val name: String, val description: String, val dueDay: Int, val reminderDays: List<Int>) {
    constructor(kameti: Kameti) : this(kameti.name, kameti.description.orEmpty(), kameti.dueDay, kameti.reminderDays.sorted())

    val isNameValid: Boolean get() = name.trim().length in 3..40
    val isDescriptionValid: Boolean get() = description.trim().length <= 500
    val isValid: Boolean get() = isNameValid && isDescriptionValid && dueDay in DUE_DAYS

    /**
     * A later due day keeps the reminders; an earlier one drops reminders
     * after it (same as the create wizard).
     */
    fun setDueDay(day: Int): EditKametiForm = copy(dueDay = day, reminderDays = reminderDays.filter { it <= day })

    fun toggleReminder(day: Int): EditKametiForm =
        copy(reminderDays = if (day in reminderDays) reminderDays - day else (reminderDays + day).sorted())

    /** Only the fields that changed; `null` when nothing did. An empty description clears it. */
    fun changes(kameti: Kameti): KametiChanges? {
        val changes = KametiChanges(
            name = name.trim().takeIf { it != kameti.name },
            description = description.trim().takeIf { it != kameti.description.orEmpty() },
            dueDay = dueDay.takeIf { it != kameti.dueDay },
            reminderDays = reminderDays.takeIf { it != kameti.reminderDays.sorted() },
        )
        return changes.takeIf { it != KametiChanges() }
    }

    companion object {
        val QUICK_DAYS = listOf(5, 10, 15)
        val DUE_DAYS = 1..28
    }
}

/**
 * Edit kameti (board AE-1), in the app's bottom sheet: one form, the values
 * that are fixed once started listed with the reason, and Save pinned at the
 * bottom.
 */
@Composable
internal fun EditKametiSheet(data: KametiDetailData, model: KametiDetailViewModel, onDismiss: () -> Unit) {
    val kameti = remember { data.kameti }
    var form by remember { mutableStateOf(EditKametiForm(kameti)) }
    var submitted by remember { mutableStateOf(false) }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    var pickingDay by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val focus = LocalFocusManager.current
    val changes = form.changes(kameti)

    KBottomSheet(stringResource(R.string.detail_edit_kameti), onDismiss, expanded = true, dismissDisabled = isBusy) { close ->
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()).kDismissesKeyboard()
                .padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.lg),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            KTextField(
                form.name, { form = form.copy(name = it) }, title = stringResource(R.string.detail_name),
                error = if (submitted && !form.isNameValid) stringResource(R.string.detail_the_name_must_be_3_to_40_characters) else null,
                capitalization = KeyboardCapitalization.Words,
            )
            KTextField(
                form.description, { form = form.copy(description = it) },
                title = stringResource(R.string.detail_description_optional),
                placeholder = stringResource(R.string.detail_e_g_cousins_rs_2_5_lakh_a),
                error = if (submitted && !form.isDescriptionValid) {
                    stringResource(R.string.detail_keep_the_description_under_500_characters)
                } else {
                    null
                },
            )

            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                FieldLabel(stringResource(R.string.detail_members_pay_by))
                KFlowRow {
                    for (day in EditKametiForm.QUICK_DAYS) {
                        KChip(ReminderLogic.ordinal(day), form.dueDay == day, onClick = { form = form.setDueDay(day) }, style = KChipStyle.Outlined)
                    }
                    val custom = form.dueDay !in EditKametiForm.QUICK_DAYS
                    // "Other" opens a list of every day (same as the create wizard).
                    KChip(
                        if (custom) ReminderLogic.ordinal(form.dueDay) else stringResource(R.string.detail_other_1a24), custom,
                        onClick = {
                            focus.clearFocus()
                            pickingDay = true
                        },
                        style = KChipStyle.Outlined,
                    )
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                FieldLabel(stringResource(R.string.detail_remind_on_these_days))
                for (week in (1..form.dueDay).chunked(5)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                        for (day in week) {
                            val label = stringResource(R.string.detail_remind_on_day_n, day)
                            KDayTile(
                                day.toString(), day in form.reminderDays, onClick = { form = form.toggleReminder(day) },
                                modifier = Modifier.weight(1f).semantics { contentDescription = label },
                            )
                        }
                        // Keep the last row's tiles the same width as the rest.
                        repeat(5 - week.size) { Row(Modifier.weight(1f)) {} }
                    }
                }
                KText(
                    stringResource(
                        if (form.reminderDays.isEmpty()) {
                            R.string.detail_no_reminders_members_wont_be_nudged_before_the
                        } else {
                            R.string.detail_reminders_go_at_10_00_am_pakistan_time
                        },
                    ),
                    KTextToken.caption, color = KColors.textSecondary,
                )
            }

            FixedCard(data)
            FailureLine(failure)
        }
        // Save stays at the bottom while the form scrolls.
        KButton(
            stringResource(R.string.detail_save_changes),
            onClick = {
                submitted = true
                if (form.isValid && changes != null) {
                    focus.clearFocus()
                    isBusy = true
                    failure = null
                    scope.launch {
                        val result = model.updateKameti(changes)
                        isBusy = false
                        if (result != null) failure = result else close()
                    }
                }
            },
            modifier = Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.sm, bottom = KSpace.md),
            enabled = changes != null, isLoading = isBusy,
        )
    }

    if (pickingDay) {
        KBottomSheet(stringResource(R.string.detail_pick_the_due_day), onDismiss = { pickingDay = false }) { close ->
            LazyColumn(Modifier.weight(1f, fill = false)) {
                items(EditKametiForm.DUE_DAYS.toList()) { day ->
                    Row(
                        Modifier.fillMaxWidth().clickable(role = Role.RadioButton) {
                            form = form.setDueDay(day)
                            close()
                        }.padding(horizontal = KSpace.xl, vertical = KSpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        KText(ReminderLogic.ordinal(day), KTextToken.body, modifier = Modifier.weight(1f))
                        if (form.dueDay == day) KIcon(KIcons.check, tint = KColors.brand)
                    }
                    KDivider(Modifier.padding(start = KSpace.xl))
                }
            }
        }
    }
}

/** The values that can't change once a kameti has started, with the reason. */
@Composable
private fun FixedCard(data: KametiDetailData) {
    val kameti = data.kameti
    val short = DateTimeFormatter.ofPattern("MMM yyyy", Locale.getDefault())
    val last = DetailLogic.monthStart(kameti, kameti.monthsN)
    val shape = RoundedCornerShape(14.dp)

    @Composable
    fun row(title: String, value: String, isLast: Boolean = false) {
        Row(Modifier.padding(vertical = KSpace.sm + 2.dp), verticalAlignment = Alignment.CenterVertically) {
            KText(title, KTextToken.body, modifier = Modifier.weight(1f), color = KColors.textSecondary)
            KText(value, KTextToken.body)
        }
        if (!isLast) KDivider()
    }

    Column(
        Modifier.fillMaxWidth().background(KColors.surface, shape).border(1.dp, KColors.border, shape)
            .padding(horizontal = KSpace.lg).padding(bottom = KSpace.md),
    ) {
        Row(
            Modifier.padding(vertical = KSpace.sm),
            horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
        ) {
            KIcon(KIcons.lockFilled, size = 14.dp)
            KText(
                stringResource(R.string.detail_fixed_once_started), KTextStyle(size = 13f, weight = FontWeight.SemiBold),
                color = KColors.textSecondary,
            )
        }
        row(stringResource(R.string.detail_slot_amount), kameti.slotAmountC.format())
        row(stringResource(R.string.detail_months), "${kameti.monthsN} · ${kameti.startMonth.format(short)} → ${last.format(short)}")
        row(stringResource(R.string.detail_most_slots_per_person), kameti.maxSlotsPerMember.toString(), isLast = true)
        KText(
            stringResource(
                if (SetupLogic.canEditSetup(data)) {
                    R.string.detail_changing_these_would_change_every_payout_until_the
                } else {
                    R.string.detail_changing_these_would_change_every_payout_to_change
                },
            ),
            KTextToken.caption, modifier = Modifier.padding(top = KSpace.xs), color = KColors.textSecondary,
        )
    }
}
