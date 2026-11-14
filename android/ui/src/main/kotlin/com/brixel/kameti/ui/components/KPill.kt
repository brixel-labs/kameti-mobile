package com.brixel.kameti.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Money

/**
 * The shape behind status chips and balance pills: an icon, a label and a
 * tinted background. Status is always icon plus text, never colour alone.
 */
@Composable
fun KPill(
    label: String,
    foreground: Color,
    background: Color,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
) {
    Row(
        modifier = modifier.background(background, CircleShape).padding(horizontal = KSpace.sm, vertical = KSpace.xs),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KSpace.xs),
    ) {
        if (icon != null) KIcon(icon, tint = foreground, size = 13.dp)
        KText(label, KTextStyle(size = 12f, weight = FontWeight.SemiBold, tabular = true), color = foreground, maxLines = 1)
    }
}

/**
 * A member's payment status for a month: paid, partial, unpaid, overdue,
 * credit (advance) or upcoming.
 */
enum class KPaymentStatus { Paid, Partial, Unpaid, Overdue, Credit, Upcoming }

@Composable
fun KStatusChip(status: KPaymentStatus, label: String, modifier: Modifier = Modifier) {
    when (status) {
        KPaymentStatus.Paid -> KPill(label, KColors.positive, KColors.positiveSubtle, modifier, KIcons.check)
        KPaymentStatus.Partial -> KPill(label, KColors.warning, KColors.warningSubtle, modifier, KIcons.circleHalf)
        KPaymentStatus.Unpaid -> KPill(label, KColors.negative, KColors.negativeSubtle, modifier, KIcons.circle)
        KPaymentStatus.Overdue -> KPill(label, KColors.negative, KColors.negativeSubtle, modifier, KIcons.clock)
        KPaymentStatus.Credit -> KPill(label, KColors.info, KColors.infoSubtle, modifier, KIcons.plusCircle)
        KPaymentStatus.Upcoming -> KPill(label, KColors.textSecondary, KColors.surfaceSunken, modifier, KIcons.more)
    }
}

/** What a balance means, independent of how it is drawn. */
sealed interface KBalanceState {
    data class Owes(val amount: Money) : KBalanceState
    data object Settled : KBalanceState
    data class Credit(val amount: Money) : KBalanceState

    companion object {
        fun of(balance: Money): KBalanceState = when {
            balance.isPositive -> Owes(balance)
            balance.isZero -> Settled
            else -> Credit(balance.abs())
        }
    }
}

/**
 * A member's running balance as a pill. A positive balance is money owed
 * ("Owes Rs 4,50,000"), zero is "Settled", a negative balance is credit.
 */
@Composable
fun KBalancePill(balance: Money, modifier: Modifier = Modifier) {
    when (val state = KBalanceState.of(balance)) {
        is KBalanceState.Owes -> KPill(
            stringResource(R.string.ui_owes_s, state.amount.format()),
            KColors.negative, KColors.negativeSubtle, modifier, KIcons.arrowUp,
        )
        KBalanceState.Settled -> KPill(
            stringResource(R.string.ui_settled), KColors.positive, KColors.positiveSubtle, modifier, KIcons.check,
        )
        is KBalanceState.Credit -> KPill(
            stringResource(R.string.ui_credit_s, state.amount.format()),
            KColors.info, KColors.infoSubtle, modifier, KIcons.plus,
        )
    }
}
