package com.brixel.kameti.feature.kametidetail

import android.icu.text.ListFormatter
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.domain.Payment
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KMoneyStyle
import com.brixel.kameti.ui.KMoneyText
import com.brixel.kameti.ui.KMoneyTone
import com.brixel.kameti.ui.KPot
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.textSubtitle
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale

/**
 * A member's read-only view (board A · Member view; FR-60 to FR-64): my due
 * this month, my payout, this month's pot and my payments. It builds no
 * write controls; the backend enforces the same rule.
 */
@Composable
internal fun MemberView(data: KametiDetailData, modifier: Modifier = Modifier) {
    val me = data.me
    Column(
        modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = KSpace.xl)
            .padding(top = KSpace.sm, bottom = KSpace.xl),
        verticalArrangement = Arrangement.spacedBy(KSpace.lg),
    ) {
        when {
            // The owner took it back to setup ("Edit setup"): turns and dues may change.
            data.kameti.status == KametiStatus.Draft -> KMessageCard(
                title = stringResource(R.string.detail_being_updated_by_the_owner),
                message = stringResource(R.string.detail_the_owner_is_changing_the_setup_your_turn),
                icon = KIcons.editSetup,
                tint = KColors.info,
            )
            me != null -> MemberContent(data, me)
            else -> KMessageCard(
                title = stringResource(R.string.detail_youre_not_a_member_of_this_kameti),
                message = stringResource(R.string.detail_ask_the_owner_to_send_you_an_invite),
                icon = KIcons.personOff,
            )
        }
    }
}

@Composable
private fun MemberContent(data: KametiDetailData, me: Member) {
    val balance = data.balances.firstOrNull { it.memberId == me.id }
    DueCard(data, balance)
    DetailLogic.nextTurn(me, data.kameti, data.current?.monthIndex ?: 1, data.slots, data.shares)?.let { turn ->
        PayoutCard(data, me, turn.monthIndex, turn.payout)
    }
    data.current?.let { PotCard(data, it) }
    PaymentsCard(data, me)
}

// Your due

@Composable
private fun DueCard(data: KametiDetailData, balance: MemberBalanceRow?) {
    val owes = balance?.owes ?: Money.ZERO
    val current = data.current
    // Before the kameti starts there's no current month: name its first month.
    val notStarted = current == null && data.today.isBefore(data.kameti.startMonth)
    val shownMonth = current?.monthStart ?: if (notStarted) data.kameti.startMonth else null
    val month = shownMonth?.let { DetailLogic.monthName(it).uppercase() }.orEmpty()
    val onBrand = KColors.textOnBrand
    val monthly = balance?.monthlyDue
    Column(
        modifier = Modifier.fillMaxWidth().background(KColors.brand, RoundedCornerShape(20.dp)).padding(KSpace.xl),
        verticalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        KText(
            when {
                month.isEmpty() -> stringResource(R.string.detail_your_due)
                notStarted -> stringResource(R.string.detail_starts_s_first_due, month)
                else -> stringResource(R.string.detail_s_your_due, month)
            },
            KTextToken.label,
            color = onBrand.copy(alpha = 0.85f),
        )
        when {
            // Nothing is due before the first month: show the first payment.
            // Paid ahead of the start counts toward it (credit shows as a negative balance).
            notStarted && monthly != null && monthly.isPositive -> {
                val firstDue = monthly + owes
                if (firstDue.isPositive) {
                    KMoneyText(firstDue, style = KMoneyStyle.DisplayLg, tone = KMoneyTone.OnBrand)
                    DueChip(data, DetailLogic.dueDate(data.kameti, 1))
                } else {
                    KText(stringResource(R.string.detail_paid_in_advance), KTextToken.displayLg, color = onBrand)
                }
            }
            owes.isPositive -> KMoneyText(owes, style = KMoneyStyle.DisplayLg, tone = KMoneyTone.OnBrand)
            monthly != null && !monthly.isPositive -> {
                KText(stringResource(R.string.detail_no_share_yet), KTextToken.displayLg, color = onBrand)
                KText(
                    stringResource(R.string.detail_youll_owe_something_once_the_owner_gives_you),
                    KTextToken.bodySm,
                    color = onBrand.copy(alpha = 0.85f),
                )
            }
            else -> KText(stringResource(R.string.detail_paid_up), KTextToken.displayLg, color = onBrand)
        }
        if (current != null && owes.isPositive) DueChip(data, DetailLogic.dueDate(data.kameti, current.monthIndex))
    }
}

@Composable
private fun DueChip(data: KametiDetailData, due: LocalDate) {
    val label = when (ChronoUnit.DAYS.between(data.today, due)) {
        0L -> stringResource(R.string.detail_due_today)
        1L -> stringResource(R.string.detail_due_tomorrow_s, DetailLogic.dayMonth(due))
        else -> stringResource(R.string.detail_due_s, DetailLogic.dayMonth(due))
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(KColors.textOnBrand.copy(alpha = 0.14f), RoundedCornerShape(12.dp))
            .padding(horizontal = KSpace.md, vertical = KSpace.sm + 2.dp),
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(KIcons.clock, tint = KColors.textOnBrand, size = 16.dp)
        KText(
            stringResource(R.string.detail_s_pay_the_owner_by_cash_or_bank, label),
            KTextToken.bodySm,
            color = KColors.textOnBrand,
        )
    }
}

// Your payout

@Composable
private fun PayoutCard(data: KametiDetailData, me: Member, monthIndex: Int, payout: Money) {
    val start = DetailLogic.monthStart(data.kameti, monthIndex)
    val locale = Locale.getDefault()
    val others = DetailLogic.recipients(data.kameti, monthIndex, data.slots, data.shares, data.members)
        .filter { it.member.id != me.id }.map { it.member.name }
    TitledCard(stringResource(R.string.detail_your_payout)) {
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md + 2.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(
                modifier = Modifier.size(56.dp).background(KColors.brandSubtle, RoundedCornerShape(14.dp)),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                KText(
                    start.format(DateTimeFormatter.ofPattern("MMM", locale)).uppercase(),
                    KTextStyle(size = 11f, weight = FontWeight.SemiBold),
                    color = KColors.onBrandSubtle,
                )
                KText(
                    start.year.toString(),
                    KTextStyle(size = 18f, weight = FontWeight.Bold, tabular = true),
                    color = KColors.onBrandSubtle,
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                KMoneyText(payout, style = KMoneyStyle.Title)
                KText(
                    if (others.isEmpty()) {
                        stringResource(R.string.detail_whole_slot_month_n, monthIndex)
                    } else {
                        stringResource(
                            R.string.detail_shared_with_s_month_n,
                            ListFormatter.getInstance(locale).format(others),
                            monthIndex,
                        )
                    },
                    KTextToken.subtitle,
                    color = KColors.textSubtitle,
                )
            }
        }
    }
}

// This month's pot

@Composable
private fun PotCard(data: KametiDetailData, current: MonthCollectionRow) {
    var showsSchedule by remember { mutableStateOf(false) }
    val recipients = DetailLogic.recipients(data.kameti, current.monthIndex, data.slots, data.shares, data.members)
    val percent = KPot.percent(current.received, current.target)
    val you = stringResource(R.string.detail_you)
    val hint = stringResource(R.string.detail_opens_the_schedule)
    // The whole card opens the schedule, not only the word in its corner.
    KCard(onClick = { showsSchedule = true }) {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CardLabel(stringResource(R.string.detail_this_months_pot), Modifier.weight(1f))
                KText(stringResource(R.string.detail_schedule), KTextToken.bodyStrong, color = KColors.brand)
                KIcon(KIcons.chevronRight, tint = KColors.brand, size = 16.dp, label = hint)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                KText(
                    if (recipients.isEmpty()) {
                        stringResource(R.string.detail_this_months_pot)
                    } else {
                        stringResource(
                            R.string.detail_to_s,
                            recipients.joinToString(" + ") { if (it.member.id == data.me?.id) you else it.member.name },
                        )
                    },
                    KTextToken.body,
                    modifier = Modifier.weight(1f),
                )
                KText("$percent%", KTextStyle(size = 15f, weight = FontWeight.SemiBold, tabular = true))
            }
            Box(Modifier.fillMaxWidth().height(8.dp).background(KColors.surfaceSunken, CircleShape)) {
                Box(
                    Modifier
                        .fillMaxWidth(percent.coerceIn(0, 100) / 100f)
                        .height(8.dp)
                        .background(KColors.brand, CircleShape),
                )
            }
            KText(
                stringResource(R.string.detail_n_of_n_members_have_paid, current.paidCount, current.memberCount),
                KTextToken.subtitle,
                color = KColors.textSubtitle,
            )
        }
    }
    if (showsSchedule) {
        KBottomSheet(title = stringResource(R.string.detail_schedule), onDismiss = { showsSchedule = false }, expanded = true) {
            Column(
                Modifier
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = KSpace.xl)
                    .padding(bottom = KSpace.xl),
            ) {
                ScheduleSection(data)
            }
        }
    }
}

// Your payments

@Composable
private fun PaymentsCard(data: KametiDetailData, me: Member) {
    val mine = DetailLogic.newestFirst(data.payments.filter { it.memberId == me.id && it.voidedAt == null })
    val upTo = data.current?.monthIndex ?: 0
    val rows = data.months.filter { it.memberId == me.id && it.monthIndex <= upTo }.sortedBy { it.monthIndex }
    TitledCard(stringResource(R.string.detail_your_payments)) {
        if (rows.isEmpty()) {
            KText(
                stringResource(R.string.detail_you_havent_made_any_payments_yet),
                KTextToken.subtitle,
                color = KColors.textSubtitle,
            )
        } else {
            Column {
                rows.forEachIndexed { index, row ->
                    val paid = mine.firstOrNull { DetailLogic.monthIndex(it.receivedOn, data.kameti) == row.monthIndex }
                    MonthRow(row, paid, showsDivider = index < rows.size - 1)
                }
            }
        }
    }
}

@Composable
private fun MonthRow(row: MemberMonthRow, payment: Payment?, showsDivider: Boolean) {
    val settled = row.status == MonthStatusCode.Paid || row.status == MonthStatusCode.Advance
    val partial = row.status == MonthStatusCode.Partial
    val tone: Color = when {
        settled -> KColors.positive
        partial -> KColors.warning
        else -> KColors.negative
    }
    val subtitle = when {
        settled && payment != null -> stringResource(
            R.string.detail_paid_s_s,
            DetailLogic.dayMonth(payment.receivedOn),
            payment.method.lowercaseLabel(),
        )
        settled -> stringResource(R.string.detail_paid)
        partial -> stringResource(R.string.detail_s_paid_so_far, row.allocated.format())
        else -> stringResource(R.string.detail_not_paid_yet)
    }
    Column {
        Row(
            Modifier.padding(vertical = KSpace.sm + 2.dp),
            horizontalArrangement = Arrangement.spacedBy(KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                Modifier.size(32.dp).background(
                    when {
                        settled -> KColors.positiveSubtle
                        partial -> KColors.warningSubtle
                        else -> KColors.negativeSubtle
                    },
                    CircleShape,
                ),
                contentAlignment = Alignment.Center,
            ) {
                KIcon(if (settled) KIcons.check else KIcons.circle, tint = tone, size = 16.dp)
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                KText(DetailLogic.monthName(row.monthStart), KTextToken.bodyStrong)
                KText(subtitle, KTextToken.caption, color = if (settled) KColors.textSecondary else tone)
            }
            KMoneyText(row.due, style = KMoneyStyle.Title)
        }
        if (showsDivider) KDivider()
    }
}

/** A card with a small upper-cased title over its content. */
@Composable
private fun TitledCard(title: String, content: @Composable () -> Unit) {
    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
            CardLabel(title)
            content()
        }
    }
}
