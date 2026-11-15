package com.brixel.kameti.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Money

enum class KMoneyStyle { Body, Title, Display, DisplayLg }

/** `OnBrand` is for amounts on a brand-coloured surface (the member's due card). */
enum class KMoneyTone { Neutral, Positive, Negative, OnBrand }

/** The only way to show an amount (`Rs 24,00,000`, compact `24 L`). */
@Composable
fun KMoneyText(
    amount: Money,
    modifier: Modifier = Modifier,
    style: KMoneyStyle = KMoneyStyle.Body,
    tone: KMoneyTone = KMoneyTone.Neutral,
    compact: Boolean = false,
) {
    val spoken = stringResource(R.string.ui_n_rupees, amount.rupees)
    KText(
        text = if (compact) amount.formatCompact() else amount.format(),
        style = when (style) {
            KMoneyStyle.Body -> KTextToken.amount
            KMoneyStyle.Title -> KTextStyle(size = 17f, weight = FontWeight.SemiBold, tabular = true)
            KMoneyStyle.Display -> KTextToken.display
            KMoneyStyle.DisplayLg -> KTextToken.displayLg
        },
        modifier = modifier.semantics { contentDescription = spoken },
        color = when (tone) {
            KMoneyTone.Neutral -> KColors.textPrimary
            KMoneyTone.Positive -> KColors.positive
            KMoneyTone.Negative -> KColors.negative
            KMoneyTone.OnBrand -> KColors.textOnBrand
        },
        maxLines = 1,
        overflow = TextOverflow.Clip,
    )
}

/**
 * The big amount with "of Rs 50,00,000" at the end of its line; when they don't
 * both fit, the second sits under the first (as on iOS) instead of the amount wrapping.
 */
@Composable
private fun PotHeadline(content: @Composable () -> Unit) {
    Layout(content, Modifier.fillMaxWidth()) { measurables, constraints ->
        val gap = KSpace.sm.roundToPx()
        val stackGap = KSpace.xs.roundToPx()
        val loose = constraints.copy(minWidth = 0, minHeight = 0)
        val placeables = measurables.map { it.measure(loose) }
        val first = placeables[0]
        val second = placeables.getOrNull(1)
        val width = constraints.maxWidth
        val sideBySide = second == null || first.width + gap + second.width <= width
        val height = when {
            second == null -> first.height
            sideBySide -> maxOf(first.height, second.height)
            else -> first.height + stackGap + second.height
        }
        layout(width, height) {
            first.placeRelative(0, if (second != null && sideBySide) height - first.height else 0)
            if (second != null) {
                if (sideBySide) second.placeRelative(width - second.width, height - second.height)
                else second.placeRelative(0, first.height + stackGap)
            }
        }
    }
}

/** What sits beside the big amount of a [KPotProgress]. */
enum class KPotHeadline {
    /** "of 50,00,000 · 47%" */
    Percent,

    /** "of Rs 50,00,000" */
    OfTarget,
    None,
}

/** Bar segments in permille of the target. */
data class KPotSegments(val collected: Int, val marked: Int, val rest: Int)

object KPot {
    /** Whole percent of [target] covered by [amount] (may pass 100). */
    fun percent(amount: Money, target: Money): Int =
        if (target.rupees <= 0) 0 else ((amount.rupees * 100) / target.rupees).toInt()

    /** Bar segments in permille of the target (integer maths, no Double). */
    fun segments(collected: Money, marked: Money, target: Money): KPotSegments {
        fun permille(m: Money): Int =
            if (target.rupees <= 0) 0 else ((m.rupees * 1000) / target.rupees).coerceIn(0, 1000).toInt()
        val c = permille(collected)
        val m = permille(collected + marked) - c
        return KPotSegments(c, m, 1000 - c - m)
    }
}

/**
 * This month's pot: "Rs 23,50,000 of 50,00,000 · 47%" over a bar.
 *
 * [marked] is money marked in a tap-to-settle session but not saved yet; it
 * is added to the headline and drawn as a lighter segment after [collected].
 * Past the target the bar is full and an "Over by Rs X" line flags it.
 */
@Composable
fun KPotProgress(
    collected: Money,
    target: Money,
    modifier: Modifier = Modifier,
    marked: Money = Money.ZERO,
    caption: String? = null,
    trailingCaption: String? = null,
    headline: KPotHeadline = KPotHeadline.Percent,
    captionAboveBar: Boolean = false,
) {
    val total = collected + marked
    val percent = KPot.percent(total, target)
    val over = total - target
    val bar = KPot.segments(collected, marked, target)
    val spoken = stringResource(R.string.ui_s_collected_of_s_n_percent, total.format(), target.format(), percent)
    val ofTarget = when (headline) {
        KPotHeadline.Percent -> stringResource(R.string.ui_of_s_n_percent, target.format(symbol = false), percent)
        KPotHeadline.OfTarget -> stringResource(R.string.ui_of_s, target.format())
        KPotHeadline.None -> null
    }

    @Composable
    fun captionRow() {
        if (caption == null && trailingCaption == null) return
        Row(Modifier.fillMaxWidth()) {
            if (caption != null) KText(caption, KTextToken.subtitleSmall, color = KColors.textSubtitle)
            Spacer(Modifier.weight(1f).padding(horizontal = KSpace.xs))
            if (trailingCaption != null) KText(trailingCaption, KTextToken.subtitleSmall, color = KColors.textSubtitle)
        }
    }

    Column(
        modifier = modifier.fillMaxWidth().clearAndSetSemantics { contentDescription = spoken },
        verticalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        PotHeadline {
            KMoneyText(total, style = KMoneyStyle.Display)
            if (ofTarget != null) {
                KText(
                    ofTarget, KTextToken.subtitle.copy(tabular = true), color = KColors.textSubtitle,
                    modifier = Modifier.padding(bottom = 5.dp), maxLines = 1,
                )
            }
        }
        if (captionAboveBar) captionRow()
        Row(Modifier.fillMaxWidth().height(KSpace.sm).clip(CircleShape).background(KColors.surfaceSunken)) {
            if (bar.collected > 0) Box(Modifier.weight(bar.collected.toFloat()).fillMaxHeight().background(KColors.brand))
            if (bar.marked > 0) Box(Modifier.weight(bar.marked.toFloat()).fillMaxHeight().background(KColors.brand.copy(alpha = 0.5f)))
            if (bar.rest > 0) Spacer(Modifier.weight(bar.rest.toFloat()))
        }
        if (over.isPositive) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.xs)) {
                KIcon(KIcons.info, tint = KColors.info, size = 14.dp)
                KText(stringResource(R.string.ui_over_by_s, over.format()), KTextToken.caption, color = KColors.info)
            }
        }
        if (!captionAboveBar) captionRow()
    }
}

/**
 * The strip shown once a month is paid out: who was paid (avatars with a
 * check), how much, and when. Green, or amber when the payout fell short.
 * Used on the Home card and on the Overview tab.
 */
@Composable
fun KPaidOutStrip(
    people: List<KPerson>,
    title: String,
    subtitle: String,
    modifier: Modifier = Modifier,
    isShort: Boolean = false,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(if (isShort) KColors.warningSubtle else KColors.positiveSubtle, RoundedCornerShape(12.dp))
            .padding(KSpace.md),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        KAvatarStack(people, showsCheck = true)
        Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
            KText(title, KTextToken.bodyStrong, color = if (isShort) KColors.warning else KColors.positiveDeep)
            KText(subtitle, KTextToken.subtitleSmall, color = if (isShort) KColors.textSubtitle else KColors.positiveDeepSubtitle)
        }
    }
}
