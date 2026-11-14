package com.brixel.kameti.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

enum class KButtonStyle { Primary, Secondary, Destructive }

/**
 * The app's main button. `Primary` is filled brand green, `Secondary` is a
 * bordered neutral button, `Destructive` is filled red. While [isLoading] it
 * shows a spinner and ignores taps, so a double tap never records twice.
 */
@Composable
fun KButton(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    style: KButtonStyle = KButtonStyle.Primary,
    icon: ImageVector? = null,
    /** A custom ~20 dp leading view such as a brand logo, shown instead of [icon]. */
    leading: (@Composable () -> Unit)? = null,
    enabled: Boolean = true,
    isLoading: Boolean = false,
    /** Fills the available width (the usual case); `false` hugs the label. */
    expand: Boolean = true,
) {
    val shape = RoundedCornerShape(KRadius.button)
    val background = when (style) {
        KButtonStyle.Primary -> KColors.brand
        KButtonStyle.Secondary -> KColors.surface
        KButtonStyle.Destructive -> KColors.negative
    }
    val foreground = if (style == KButtonStyle.Secondary) KColors.textPrimary else KColors.textOnBrand
    Box(
        modifier = modifier
            .then(if (expand) Modifier.fillMaxWidth() else Modifier)
            .height(KSize.buttonHeight)
            .alpha(if (enabled) 1f else 0.45f)
            .clip(shape)
            .background(background)
            .then(if (style == KButtonStyle.Secondary) Modifier.border(1.dp, KColors.borderStrong, shape) else Modifier)
            .clickable(enabled = enabled && !isLoading, role = Role.Button, onClick = onClick)
            .padding(horizontal = KSpace.xl),
        contentAlignment = Alignment.Center,
    ) {
        Row(
            modifier = Modifier.alpha(if (isLoading) 0f else 1f),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
        ) {
            if (leading != null) leading() else if (icon != null) KIcon(icon, tint = foreground)
            KText(title, KTextToken.bodyStrong, color = foreground, maxLines = 1)
        }
        if (isLoading) CircularProgressIndicator(Modifier.size(20.dp), color = foreground, strokeWidth = 2.dp)
    }
}

/** An icon-only button with a 44 dp touch area. [label] is read by screen readers. */
@Composable
fun KIconButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    tint: Color = KColors.textSecondary,
    enabled: Boolean = true,
) {
    Box(
        modifier = modifier
            .size(KSize.minTouch)
            .clip(CircleShape)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        KIcon(icon, tint = if (enabled) tint else KColors.textTertiary, size = 22.dp, label = label)
    }
}

enum class KTonalStyle { Tonal, Neutral }

/**
 * A compact action capsule. `Tonal` is the secondary action (light green
 * with green text); `Neutral` is white with a grey border.
 */
@Composable
fun KTonalButton(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    style: KTonalStyle = KTonalStyle.Tonal,
) {
    val foreground = if (style == KTonalStyle.Tonal) KColors.onBrandSubtle else KColors.textPrimary
    Row(
        modifier = modifier
            .height(36.dp)
            .clip(CircleShape)
            .background(if (style == KTonalStyle.Tonal) KColors.brandSubtle else KColors.surface)
            .then(if (style == KTonalStyle.Neutral) Modifier.border(1.dp, KColors.border, CircleShape) else Modifier)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        if (icon != null) KIcon(icon, tint = foreground, size = 16.dp)
        KText(title, KTextStyle(size = 13f, weight = FontWeight.SemiBold), color = foreground, maxLines = 1)
    }
}

enum class KChipStyle { Filled, Outlined }

/**
 * A pill that can be selected. `Filled` turns solid brand colour when on;
 * `Outlined` keeps a light fill with a brand border (the due-day chips).
 */
@Composable
fun KChip(
    title: String,
    isOn: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    style: KChipStyle = KChipStyle.Filled,
    enabled: Boolean = true,
) {
    val foreground = if (isOn && style == KChipStyle.Filled) KColors.textOnBrand else KColors.textPrimary
    val background = when {
        !isOn -> KColors.surface
        style == KChipStyle.Filled -> KColors.brand
        else -> KColors.brandSubtle
    }
    Row(
        modifier = modifier
            .alpha(if (enabled) 1f else 0.45f)
            .clip(CircleShape)
            .background(background)
            .border(
                if (isOn && style == KChipStyle.Outlined) 1.5.dp else 1.dp,
                if (isOn) KColors.brand else KColors.border, CircleShape,
            )
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .semantics { selected = isOn }
            .padding(horizontal = KSpace.lg, vertical = KSpace.sm + 2.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KSpace.xs),
    ) {
        if (icon != null) KIcon(icon, tint = foreground, size = 16.dp)
        KText(title, KTextToken.bodyStrong, color = foreground, maxLines = 1)
    }
}

/** A rounded-square day tile for a 5-column grid; solid brand colour when on. */
@Composable
fun KDayTile(title: String, isOn: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(KRadius.input)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp)
            .clip(shape)
            .background(if (isOn) KColors.brand else KColors.surface)
            .border(1.dp, if (isOn) KColors.brand else KColors.border, shape)
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { selected = isOn },
        contentAlignment = Alignment.Center,
    ) {
        KText(
            title, KTextToken.bodyStrong.copy(tabular = true),
            color = if (isOn) KColors.textOnBrand else KColors.textPrimary, textAlign = TextAlign.Center,
        )
    }
}

/** A small − value + control for use inside a settings row. */
@Composable
fun KCompactStepper(
    value: Int,
    range: IntRange,
    decreaseLabel: String,
    increaseLabel: String,
    onChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    @Composable
    fun square(icon: ImageVector, label: String, enabled: Boolean, action: () -> Unit) {
        val shape = RoundedCornerShape(KRadius.input)
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(shape)
                .background(KColors.surface)
                .border(1.dp, KColors.border, shape)
                .clickable(enabled = enabled, role = Role.Button, onClick = action),
            contentAlignment = Alignment.Center,
        ) {
            KIcon(icon, tint = if (enabled) KColors.textPrimary else KColors.textTertiary, size = 18.dp, label = label)
        }
    }
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
        square(KIcons.minus, decreaseLabel, value > range.first) { onChange(value - 1) }
        KText(
            "$value", KTextToken.title.copy(tabular = true),
            modifier = Modifier.widthIn(min = 20.dp), textAlign = TextAlign.Center,
        )
        square(KIcons.plus, increaseLabel, value < range.last) { onChange(value + 1) }
    }
}

/** A − value + control with round buttons, the height of a field. */
@Composable
fun KStepper(
    value: Int,
    range: IntRange,
    decreaseLabel: String,
    increaseLabel: String,
    onChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    @Composable
    fun round(icon: ImageVector, label: String, enabled: Boolean, action: () -> Unit) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(if (enabled) KColors.brandSubtle else KColors.surfaceSunken)
                .clickable(enabled = enabled, role = Role.Button, onClick = action),
            contentAlignment = Alignment.Center,
        ) {
            KIcon(icon, tint = if (enabled) KColors.onBrandSubtle else KColors.textTertiary, size = 18.dp, label = label)
        }
    }
    val shape = RoundedCornerShape(KRadius.input)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(KSize.fieldHeight)
            .background(KColors.surface, shape)
            .border(1.dp, KColors.border, shape)
            .padding(horizontal = KSpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        round(KIcons.minus, decreaseLabel, value > range.first) { onChange(value - 1) }
        KText("$value", KTextToken.title.copy(tabular = true), modifier = Modifier.weight(1f), textAlign = TextAlign.Center)
        round(KIcons.plus, increaseLabel, value < range.last) { onChange(value + 1) }
    }
}

/** The six-dot drag handle (two columns of three) in a light rounded square. */
@Composable
fun KGripHandle(modifier: Modifier = Modifier, boxed: Boolean = true) {
    Box(
        modifier = modifier
            .size(36.dp)
            .background(if (boxed) KColors.surfaceSunken else Color.Transparent, RoundedCornerShape(10.dp))
            .clearAndSetSemantics {},
        contentAlignment = Alignment.Center,
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            repeat(3) {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    repeat(2) { Spacer(Modifier.size(3.5.dp).background(KColors.textTertiary, CircleShape)) }
                }
            }
        }
    }
}
