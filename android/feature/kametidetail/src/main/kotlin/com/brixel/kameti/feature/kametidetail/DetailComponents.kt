package com.brixel.kameti.feature.kametidetail

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.MonthCollectionState
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KAvatarSize
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMoneyStyle
import com.brixel.kameti.ui.KMoneyText
import com.brixel.kameti.ui.KPill
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTonalButton
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * A list row: avatar or icon, title, optional subtitle and a trailing view.
 * With [onClick] the whole row is tappable, including the empty space
 * between the name and the status.
 */
@Composable
internal fun DetailRow(
    title: String,
    leading: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    showsDivider: Boolean = true,
    onClick: (() -> Unit)? = null,
    trailing: @Composable () -> Unit = {},
) {
    Column(modifier.then(if (onClick != null) Modifier.clickable(role = Role.Button, onClick = onClick) else Modifier)) {
        Row(
            Modifier.padding(vertical = KSpace.md),
            horizontalArrangement = Arrangement.spacedBy(KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            leading()
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                KText(title, KTextToken.bodyStrong)
                if (subtitle != null) KText(subtitle, KTextToken.subtitle, color = KColors.textSubtitle)
            }
            trailing()
        }
        if (showsDivider) KDivider()
    }
}

/** A [DetailRow] for a member: their avatar and name. */
@Composable
internal fun MemberRow(
    member: Member,
    members: List<Member>,
    subtitle: String? = null,
    showsDivider: Boolean = true,
    onClick: (() -> Unit)? = null,
    trailing: @Composable () -> Unit = {},
) {
    DetailRow(
        title = member.name,
        leading = { KAvatar(member.name, DetailLogic.colorIndex(member, members), size = KAvatarSize.Medium) },
        subtitle = subtitle,
        showsDivider = showsDivider,
        onClick = onClick,
        trailing = trailing,
    )
}

internal fun isPaidOut(state: MonthCollectionState): Boolean =
    state == MonthCollectionState.PaidOut || state == MonthCollectionState.PaidOutShort

/** The state of a month's collection and payout, as a plain coloured pill. */
@Composable
internal fun CollectionStatePill(state: MonthCollectionState) {
    when (state) {
        MonthCollectionState.Upcoming ->
            KPill(stringResource(R.string.detail_upcoming), KColors.textSecondary, KColors.surfaceSunken)
        MonthCollectionState.Collecting, MonthCollectionState.PartiallyPaidOut ->
            KPill(stringResource(R.string.detail_collecting), KColors.info, KColors.infoSubtle)
        MonthCollectionState.FullyCollected ->
            KPill(stringResource(R.string.detail_collected), KColors.positive, KColors.positiveSubtle)
        MonthCollectionState.PaidOut ->
            KPill(stringResource(R.string.detail_paid_out), KColors.positive, KColors.positiveSubtle)
        MonthCollectionState.PaidOutShort ->
            KPill(stringResource(R.string.detail_paid_out_short), KColors.warning, KColors.warningSubtle)
    }
}

@Composable
internal fun MonthStatusCode.label(): String = stringResource(
    when (this) {
        MonthStatusCode.Paid -> R.string.detail_paid
        MonthStatusCode.Partial -> R.string.detail_partial
        MonthStatusCode.Unpaid -> R.string.detail_unpaid
        MonthStatusCode.Overdue -> R.string.detail_overdue
        MonthStatusCode.Advance -> R.string.detail_advance
        MonthStatusCode.Upcoming -> R.string.detail_upcoming
    },
)

/** A month status as a plain coloured pill, as on the overview rows. The label carries the meaning. */
@Composable
internal fun StatusTextPill(status: MonthStatusCode) {
    val (foreground, background) = when (status) {
        MonthStatusCode.Paid -> KColors.positive to KColors.positiveSubtle
        MonthStatusCode.Partial -> KColors.warning to KColors.warningSubtle
        MonthStatusCode.Unpaid, MonthStatusCode.Overdue -> KColors.negative to KColors.negativeSubtle
        MonthStatusCode.Advance -> KColors.info to KColors.infoSubtle
        MonthStatusCode.Upcoming -> KColors.textSecondary to KColors.surfaceSunken
    }
    KPill(status.label(), foreground, background)
}

@Composable
internal fun PaymentMethod.label(): String = stringResource(
    when (this) {
        PaymentMethod.Cash -> R.string.detail_cash_4a87
        PaymentMethod.BankTransfer -> R.string.detail_bank_1044
        PaymentMethod.Other -> R.string.detail_other_1a24
    },
)

/** The method inside a sentence: "paid 10 Nov · cash". */
@Composable
internal fun PaymentMethod.lowercaseLabel(): String = stringResource(
    when (this) {
        PaymentMethod.Cash -> R.string.detail_cash_e5b9
        PaymentMethod.BankTransfer -> R.string.detail_bank_bf7a
        PaymentMethod.Other -> R.string.detail_other_3520
    },
)

/** A first name for tight spaces ("Ali Raza" becomes "Ali"). */
internal fun firstName(name: String): String = name.split(" ").firstOrNull { it.isNotEmpty() } ?: name

/** "Owes Rs 4,50,000", "Settled" or "Credit Rs 1,25,000" as a small pill. */
@Composable
internal fun BalanceChip(balance: MemberBalanceRow) {
    when {
        balance.owes.isPositive ->
            KPill(stringResource(R.string.detail_owes_s, balance.owes.format()), KColors.negative, KColors.negativeSubtle)
        balance.credit.isPositive ->
            KPill(stringResource(R.string.detail_credit_s, balance.credit.format()), KColors.info, KColors.infoSubtle)
        else -> KPill(stringResource(R.string.detail_settled), KColors.positive, KColors.positiveSubtle)
    }
}

internal enum class PaymentKind { Received, PaidOut }

/**
 * One payment or payout in the money list: a round icon, who and how, and
 * the amount. A voided one is greyed and struck through (board A v2 · Payments).
 */
@Composable
internal fun PaymentRow(
    kind: PaymentKind,
    title: String,
    subtitle: String,
    amount: Money,
    isVoided: Boolean = false,
    showsDivider: Boolean = true,
) {
    val tint = when {
        isVoided -> KColors.textSecondary
        kind == PaymentKind.Received -> KColors.positive
        else -> KColors.warning
    }
    val background = when {
        isVoided -> KColors.surfaceSunken
        kind == PaymentKind.Received -> KColors.positiveSubtle
        else -> KColors.warningSubtle
    }
    Column {
        Row(
            Modifier.padding(vertical = KSpace.sm + 2.dp),
            horizontalArrangement = Arrangement.spacedBy(KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.size(36.dp).background(background, CircleShape), contentAlignment = Alignment.Center) {
                KIcon(
                    when {
                        isVoided -> KIcons.closeCircle
                        kind == PaymentKind.Received -> KIcons.arrowDown
                        else -> KIcons.arrowUp
                    },
                    tint = tint,
                    size = 18.dp,
                )
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                KText(title, KTextToken.bodyStrong, color = if (isVoided) KColors.textSecondary else KColors.textPrimary)
                KText(subtitle, KTextToken.subtitleSmall, color = KColors.textSubtitle)
            }
            if (isVoided) {
                // Struck through: this amount no longer counts.
                KText(
                    androidx.compose.ui.text.AnnotatedString(
                        amount.format(),
                        androidx.compose.ui.text.SpanStyle(textDecoration = TextDecoration.LineThrough),
                    ),
                    KTextStyle(size = 17f, weight = FontWeight.SemiBold, tabular = true),
                    modifier = Modifier.alpha(0.6f),
                )
            } else {
                KMoneyText(amount, style = KMoneyStyle.Title)
            }
        }
        if (showsDivider) KDivider()
    }
}

/**
 * The payout month grid with a legend and a details card for the selected
 * month (board A v2 · Schedule, FR-62).
 */
@Composable
internal fun ScheduleSection(
    data: KametiDetailData,
    modifier: Modifier = Modifier,
    /** When set (owner), a started month that isn't paid out gets a Pay out button. */
    onPayOut: ((Int) -> Unit)? = null,
) {
    val kameti = data.kameti
    val byMonth = data.collections.associateBy { it.monthIndex }
    val myId = data.me?.id
    val currentIndex = data.current?.monthIndex
    var selected by rememberSaveable { mutableStateOf<Int?>(null) }
    val chosen = selected ?: currentIndex
    val you = stringResource(R.string.detail_you)

    Column(modifier, verticalArrangement = Arrangement.spacedBy(KSpace.lg)) {
        Legend()
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
            for (rowOfMonths in (1..maxOf(kameti.monthsN, 1)).chunked(4)) {
                Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                    for (month in rowOfMonths) {
                        val recipients = DetailLogic.recipients(kameti, month, data.slots, data.shares, data.members)
                        val paidOut = byMonth[month]?.let { isPaidOut(it.state) } ?: false
                        val names = recipients.joinToString(" + ") { if (it.member.id == myId) you else firstName(it.member.name) }
                        MonthTile(
                            monthStart = DetailLogic.monthStart(kameti, month),
                            names = if (paidOut) "$names ✓" else names,
                            isPaidOut = paidOut,
                            isNow = month == currentIndex,
                            isYourTurn = recipients.any { it.member.id == myId },
                            isSelected = month == chosen,
                            onClick = { selected = month },
                            modifier = Modifier.weight(1f),
                        )
                    }
                    // Keep the last row's tiles the same width as the others.
                    repeat(4 - rowOfMonths.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
        if (chosen != null) {
            MonthDetails(data, chosen, byMonth[chosen], onPayOut)
        } else {
            KText(
                stringResource(R.string.detail_pick_a_month_to_see_who_receives_the),
                KTextToken.subtitle,
                color = KColors.textSubtitle,
            )
        }
    }
}

@Composable
private fun Legend() {
    @Composable
    fun item(title: String, mark: Modifier) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(12.dp).then(mark))
            KText(title, KTextToken.subtitleSmall, color = KColors.textSubtitle)
        }
    }
    val small = RoundedCornerShape(3.dp)
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
        item(stringResource(R.string.detail_paid_out), Modifier.background(KColors.brand, small))
        item(stringResource(R.string.detail_now), Modifier.border(2.dp, KColors.info, small))
        item(
            stringResource(R.string.detail_your_turn),
            Modifier.background(KColors.warningSubtle, small).border(1.dp, KColors.warning, small),
        )
    }
}

@Composable
private fun MonthTile(
    monthStart: LocalDate,
    names: String,
    isPaidOut: Boolean,
    isNow: Boolean,
    isYourTurn: Boolean,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val label = monthStart.format(DateTimeFormatter.ofPattern("MMM yy", Locale.getDefault())).uppercase()
    val now = stringResource(R.string.detail_now).uppercase()
    val labelColor = when {
        isPaidOut -> KColors.textOnBrand.copy(alpha = 0.8f)
        isNow -> KColors.info
        isYourTurn -> KColors.warning
        else -> KColors.textSecondary
    }
    val background = when {
        isPaidOut -> KColors.brand
        isYourTurn -> KColors.warningSubtle
        else -> KColors.surface
    }
    val border = when {
        isNow -> KColors.info
        isSelected -> KColors.textPrimary
        isYourTurn -> KColors.warning
        isPaidOut -> KColors.brand
        else -> KColors.border
    }
    val shape = RoundedCornerShape(12.dp)
    Column(
        modifier = modifier
            .aspectRatio(1f)
            .clip(shape)
            .background(background)
            .border(if (isNow || isSelected) 2.dp else 1.dp, border, shape)
            .clickable(role = Role.Button, onClick = onClick)
            .semantics(mergeDescendants = true) { selected = isSelected }
            .padding(KSpace.sm),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        KText(
            if (isNow) "$label · $now" else label,
            KTextStyle(size = if (isNow) 10f else 12f, weight = FontWeight.Bold),
            color = labelColor,
            maxLines = 1,
        )
        KText(
            names,
            KTextStyle(size = 12f, weight = FontWeight.Medium),
            color = when {
                isPaidOut -> KColors.textOnBrand
                isYourTurn -> KColors.warning
                else -> KColors.textPrimary
            },
            maxLines = 2,
        )
    }
}

@Composable
private fun MonthDetails(data: KametiDetailData, monthIndex: Int, row: MonthCollectionRow?, onPayOut: ((Int) -> Unit)?) {
    val recipients = DetailLogic.recipients(data.kameti, monthIndex, data.slots, data.shares, data.members)
    val month = DetailLogic.monthTitle(DetailLogic.monthStart(data.kameti, monthIndex))
    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm + 2.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                KText(
                    stringResource(R.string.detail_s_month_n, month, monthIndex),
                    KTextToken.bodyStrong,
                    modifier = Modifier.weight(1f),
                )
                if (row != null) CollectionStatePill(row.state)
            }
            if (recipients.isEmpty()) {
                KText(
                    stringResource(R.string.detail_no_one_is_paid_out_this_month_yet),
                    KTextToken.subtitle,
                    color = KColors.textSubtitle,
                )
            } else {
                for (recipient in recipients) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        KText(
                            if (recipient.member.id == data.me?.id) stringResource(R.string.detail_you) else recipient.member.name,
                            KTextToken.body,
                            modifier = Modifier.weight(1f),
                        )
                        KMoneyText(recipient.payout, style = KMoneyStyle.Title)
                    }
                }
                if (onPayOut != null && row != null && !isPaidOut(row.state) && row.monthIndex <= (data.current?.monthIndex ?: 0)) {
                    KTonalButton(
                        stringResource(R.string.detail_pay_out_this_month),
                        onClick = { onPayOut(monthIndex) },
                        icon = KIcons.arrowUpRight,
                    )
                }
            }
        }
    }
}

/** A tinted box for a small figure with its label under it. */
@Composable
internal fun Figure(label: String, value: String, modifier: Modifier = Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        KText(value, KTextToken.bodyStrong)
        KText(label, KTextToken.bodySm, color = KColors.textSecondary)
    }
}

/** An upper-cased small label, as on the cards' first line. */
@Composable
internal fun CardLabel(text: String, modifier: Modifier = Modifier, color: Color = KColors.textSecondary) {
    KText(text.uppercase(), KTextToken.label, modifier = modifier, color = color)
}

