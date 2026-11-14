package com.brixel.kameti.feature.createkameti

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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Member
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KCheckbox
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDates
import com.brixel.kameti.ui.KGripHandle
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KReorderList
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTonalButton
import com.brixel.kameti.ui.KTonalStyle
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle

/** Step 5 (AC-5): who gets the pot when. Hold a row and drag to reorder. */
@Composable
internal fun OrderStep(state: WizardState, model: CreateWizardViewModel) {
    val original = remember(state.slots) { state.slots.sortedBy { it.payoutMonthIndex }.map { it.id } }
    var order by remember(original) { mutableStateOf(original) }
    val me = state.selfMember?.id
    val byId = state.members.associateBy { it.id }
    val you = stringResource(R.string.create_you)
    val empty = stringResource(R.string.create_empty)

    Column(Modifier.fillMaxSize()) {
        Column(
            Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.xl, bottom = KSpace.sm),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            WizardHeading(
                stringResource(R.string.create_who_gets_the_pot_when),
                stringResource(R.string.create_hold_and_drag_to_reorder_members_will_see),
            )
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                KText(
                    stringResource(R.string.create_n_months, order.size).uppercase(), KTextToken.label,
                    modifier = Modifier.weight(1f), color = KColors.textSecondary,
                )
                KTonalButton(stringResource(R.string.create_shuffle), { order = order.shuffled() }, icon = KIcons.shuffle, style = KTonalStyle.Neutral)
                KTonalButton(stringResource(R.string.create_reset), { order = original }, style = KTonalStyle.Neutral)
            }
        }
        KReorderList(
            ids = order, onReorder = { order = it }, modifier = Modifier.weight(1f),
            contentPadding = PaddingValues(horizontal = KSpace.xl, vertical = KSpace.xs),
        ) { index, slotId ->
            // A numbered row: who gets the pot that month, with a grip. The
            // owner's own turns have a filled green number.
            val date = addingMonths(index, state.startMonth)
            val active = PlanChecks.activeShares(slotId, state.shares)
            val mine = active.any { it.memberId == me }
            val names = active.mapNotNull { share -> byId[share.memberId]?.let { if (it.id == me) you else it.name } }
            val shape = RoundedCornerShape(KRadius.card)
            val spoken = stringResource(R.string.create_drag_to_move_s, KDates.monthLabel(date))
            Row(
                Modifier.fillMaxWidth().background(KColors.surface, shape).border(1.dp, KColors.border, shape)
                    .semantics(mergeDescendants = true) { contentDescription = spoken }
                    .padding(start = KSpace.md, end = KSpace.sm, top = KSpace.sm + 2.dp, bottom = KSpace.sm + 2.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(KSpace.md),
            ) {
                Box(
                    Modifier.size(32.dp).background(if (mine) KColors.brand else KColors.surface, CircleShape)
                        .then(if (mine) Modifier else Modifier.border(1.dp, KColors.border, CircleShape)),
                    contentAlignment = Alignment.Center,
                ) {
                    KText(
                        "${index + 1}", KTextToken.bodyStrong.copy(tabular = true),
                        color = if (mine) KColors.textOnBrand else KColors.textPrimary,
                    )
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                    KText(if (names.isEmpty()) empty else names.joinToString(" + "), KTextToken.bodyStrong, maxLines = 1)
                    KText(KDates.shortMonthLabel(date), KTextToken.subtitleSmall, color = KColors.textSubtitle)
                }
                KGripHandle(boxed = false)
            }
        }
        WizardFooter(
            stringResource(R.string.create_next_review), action = { model.launch { saveOrder(order) } },
            isLoading = state.isBusy, onBack = { model.back() },
        )
    }
}

/** Step 6 (AC-6): a summary, the pre-start checks, then start or save as draft. */
@Composable
internal fun ReviewStep(state: WizardState, model: CreateWizardViewModel, onStart: (String) -> Unit, onSaveDraft: () -> Unit) {
    // Emailing invites on start is shown as in the design; it isn't wired to
    // the invites backend yet, so the box does nothing until it is.
    var emailInvites by rememberSaveable { mutableStateOf(true) }
    val checks = state.checks
    val amount = state.slotAmount ?: Money.ZERO
    val names = state.members.associate { it.id to it.name }
    val first = state.slots.minByOrNull { it.payoutMonthIndex }
    val firstNames = first?.let { slot -> PlanChecks.activeShares(slot.id, state.shares).mapNotNull { names[it.memberId] } }.orEmpty()
    val noEmail = state.members.filter { it.profileId == null && state.emails[it.id] == null }
    val withEmail = state.members.count { it.profileId == null && state.emails[it.id] != null }

    Column(Modifier.fillMaxSize()) {
        StepBody(Modifier.weight(1f)) {
            WizardHeading(stringResource(R.string.create_ready_to_start), "")
            SummaryCard(state, amount, firstNames) { model.goTo(WizardStep.Basics) }
            ChecksCard(state, checks, amount, noEmail)
            if (withEmail > 0) {
                KCheckbox(
                    emailInvites, { emailInvites = it },
                    modifier = Modifier.fillMaxWidth().background(KColors.brandSubtle, RoundedCornerShape(KRadius.input)).padding(KSpace.md),
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        KText(stringResource(R.string.create_email_invites_to_n_people_now, withEmail), KTextToken.bodyStrong)
                        KText(stringResource(R.string.create_you_can_also_send_them_later_from_members), KTextToken.subtitle, color = KColors.textSubtitle)
                    }
                }
            }
            KText(stringResource(R.string.create_once_started_the_slot_amount_and_number_of), KTextToken.subtitle, color = KColors.textSubtitle)
            if (!checks.passes) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.xs)) {
                    KIcon(KIcons.warning, tint = KColors.warning, size = 16.dp)
                    KText(stringResource(R.string.create_fix_the_checks_above_before_starting), KTextToken.bodySm, color = KColors.warning)
                }
            }
        }
        WizardFooter(
            stringResource(R.string.create_start_kameti),
            action = { model.launch { start()?.let(onStart) } },
            isEnabled = checks.passes, isLoading = state.isBusy, onBack = { model.back() },
            secondary = {
                KText(
                    stringResource(R.string.create_save_draft), KTextToken.bodyStrong, color = KColors.onBrandSubtle,
                    modifier = Modifier.clip(RoundedCornerShape(KRadius.sm)).clickable(role = Role.Button, onClick = onSaveDraft)
                        .padding(horizontal = KSpace.lg, vertical = KSpace.sm),
                )
            },
        )
    }
}

@Composable
private fun SummaryCard(state: WizardState, amount: Money, firstNames: List<String>, onEdit: () -> Unit) {
    val start = KDates.shortMonthLabel(state.startMonth)
    val end = KDates.shortMonthLabel(addingMonths(state.months - 1, state.startMonth))
    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                KText(state.name, KTextToken.title, modifier = Modifier.weight(1f))
                KText(
                    stringResource(R.string.create_edit), KTextToken.bodyStrong, color = KColors.brand,
                    modifier = Modifier.clip(RoundedCornerShape(KRadius.sm)).clickable(role = Role.Button, onClick = onEdit).padding(KSpace.xs),
                )
            }
            KeyValueRow(stringResource(R.string.create_pot_each_month), state.pot.format(), emphasis = true)
            KeyValueRow(stringResource(R.string.create_slot_amount), stringResource(R.string.create_s_month, amount.format()))
            KeyValueRow(stringResource(R.string.create_runs), stringResource(R.string.create_s_s_n_months, start, end, state.months))
            KeyValueRow(stringResource(R.string.create_members), stringResource(R.string.create_n_people, state.members.size))
            KeyValueRow(
                stringResource(R.string.create_due_by),
                if (state.reminderDays.isEmpty()) {
                    stringResource(R.string.create_s_no_reminders, ordinal(state.dueDay))
                } else {
                    stringResource(R.string.create_s_reminders_s, ordinal(state.dueDay), state.reminderDays.joinToString(", "))
                },
            )
            KeyValueRow(
                stringResource(R.string.create_first_payout),
                if (firstNames.isEmpty()) stringResource(R.string.create_not_set_yet) else "${firstNames.joinToString(" + ")} · $start",
            )
        }
    }
}

@Composable
private fun ChecksCard(state: WizardState, checks: PlanChecks, amount: Money, noEmail: List<Member>) {
    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
            KText(stringResource(R.string.create_checks).uppercase(), KTextToken.label, color = KColors.textSecondary)
            CheckRow(
                checks.slotsFilled,
                ok = stringResource(R.string.create_all_n_slots_are_filled, state.slots.size),
                bad = stringResource(R.string.create_n_slots_are_empty, checks.emptySlots.size),
            )
            CheckRow(
                checks.slotsAddUp,
                ok = stringResource(R.string.create_every_slot_adds_up_to_s, amount.format()),
                bad = stringResource(R.string.create_n_slots_dont_add_up_to_s, checks.badSlots.size, amount.format()),
            )
            CheckRow(
                state.slots.map { it.payoutMonthIndex }.toSet().size == state.slots.size,
                ok = stringResource(R.string.create_everyone_has_a_payout_month),
                bad = stringResource(R.string.create_some_slots_dont_have_their_own_payout_month),
            )
            CheckRow(
                checks.withinLimit,
                ok = stringResource(R.string.create_no_one_is_over_n_slots, state.maxSlotsPerMember),
                bad = stringResource(R.string.create_s_over_n_slots, listAnd(checks.overLimit.map { it.name }), state.maxSlotsPerMember),
            )
            if (noEmail.isNotEmpty()) {
                // A heads-up, not a blocker: they can still be added by link later.
                Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                    KIcon(KIcons.error, tint = KColors.warning, size = 18.dp)
                    KText(
                        stringResource(
                            if (noEmail.size == 1) R.string.create_s_has_no_email_so_no_app_invite else R.string.create_s_have_no_email_so_no_app_invite,
                            listAnd(noEmail.map { it.name }),
                        ),
                        KTextToken.body, color = KColors.warning,
                    )
                }
            }
        }
    }
}

@Composable
private fun CheckRow(passes: Boolean, ok: String, bad: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
        KIcon(
            if (passes) KIcons.check else KIcons.warningFilled,
            tint = if (passes) KColors.positive else KColors.warning, size = 18.dp,
        )
        KText(if (passes) ok else bad, KTextToken.body, color = if (passes) KColors.textPrimary else KColors.warning)
    }
}
