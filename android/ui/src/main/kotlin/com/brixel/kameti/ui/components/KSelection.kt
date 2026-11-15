package com.brixel.kameti.ui

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.FlowRowScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** One choice in a select field, segmented control or tab row. */
data class KOption<T>(val value: T, val label: String)

/** Wraps its children onto as many lines as needed. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun KFlowRow(modifier: Modifier = Modifier, spacing: Dp = KSpace.sm, content: @Composable FlowRowScope.() -> Unit) {
    FlowRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(spacing),
        verticalArrangement = Arrangement.spacedBy(spacing),
        content = content,
    )
}

/** A field that opens a bottom sheet of options (a month, a day, ...). */
@Composable
fun <T> KSelectField(
    title: String,
    selection: T,
    options: List<KOption<T>>,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier,
    sheetTitle: String = title,
) {
    var isOpen by remember { mutableStateOf(false) }
    KFieldButton(
        value = options.firstOrNull { it.value == selection }?.label ?: "",
        onClick = { isOpen = true },
        modifier = modifier,
        title = title,
    )
    if (isOpen) {
        KBottomSheet(title = sheetTitle, onDismiss = { isOpen = false }) { close ->
            val current = options.indexOfFirst { it.value == selection }
            val list = rememberLazyListState(initialFirstVisibleItemIndex = maxOf(current - 3, 0))
            LazyColumn(state = list, modifier = Modifier.fillMaxWidth()) {
                itemsIndexed(options) { _, option ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(option.value); close() }
                            .padding(horizontal = KSpace.xl, vertical = KSpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        KText(option.label, KTextToken.body, modifier = Modifier.weight(1f))
                        if (option.value == selection) KIcon(KIcons.check, tint = KColors.brand)
                    }
                    HorizontalDivider(Modifier.padding(start = KSpace.xl), color = KColors.divider)
                }
            }
        }
    }
}

/**
 * The design's switch: a green capsule track with a white knob that slides.
 * The whole row toggles.
 */
@Composable
fun KToggle(
    isOn: Boolean,
    onChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    label: @Composable () -> Unit,
) {
    val knob by animateDpAsState(if (isOn) 20.dp else 0.dp, spring(dampingRatio = 0.7f), label = "knob")
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(
                enabled = enabled, role = Role.Switch, indication = null,
                interactionSource = remember { MutableInteractionSource() },
            ) { onChange(!isOn) }
            .semantics { selected = isOn },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        Box(Modifier.weight(1f)) { label() }
        Box(
            modifier = Modifier
                .size(width = 52.dp, height = 32.dp)
                .background(if (isOn) KColors.brand else KColors.borderStrong, CircleShape)
                .padding(3.dp),
        ) {
            Box(Modifier.offset(x = knob).size(26.dp).shadow(2.dp, CircleShape).background(Color.White, CircleShape))
        }
    }
}

/** A rounded-square checkbox with the label on its trailing side. The whole row toggles. */
@Composable
fun KCheckbox(
    isOn: Boolean,
    onChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    label: @Composable () -> Unit,
) {
    val tick by animateFloatAsState(if (isOn) 1f else 0f, spring(dampingRatio = 0.6f), label = "tick")
    val shape = RoundedCornerShape(7.dp)
    Row(
        modifier = modifier
            .clickable(
                role = Role.Checkbox, indication = null,
                interactionSource = remember { MutableInteractionSource() },
            ) { onChange(!isOn) }
            .semantics { selected = isOn },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        Box(
            modifier = Modifier
                .size(26.dp)
                .background(if (isOn) KColors.brand else KColors.surface, shape)
                .border(1.5.dp, if (isOn) KColors.brand else KColors.borderStrong, shape),
            contentAlignment = Alignment.Center,
        ) {
            if (tick > 0f) KIcon(KIcons.check, tint = KColors.textOnBrand, size = 18.dp, modifier = Modifier.scale(0.5f + tick / 2))
        }
        label()
    }
}

/**
 * A segmented control in the design's look: a light track with a white,
 * sliding selection.
 */
@Composable
fun <T> KSegmented(
    options: List<KOption<T>>,
    selection: T,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier,
) {
    val index = options.indexOfFirst { it.value == selection }.coerceAtLeast(0)
    BoxWithConstraints(
        modifier = modifier.fillMaxWidth().background(KColors.surfaceSunken, RoundedCornerShape(12.dp)).padding(4.dp),
    ) {
        val each = maxWidth / maxOf(options.size, 1)
        val x by animateDpAsState(each * index, tween(220), label = "segment")
        Box(
            Modifier.offset(x = x).width(each).height(40.dp)
                .shadow(1.dp, RoundedCornerShape(9.dp)).background(KColors.surface, RoundedCornerShape(9.dp)),
        )
        Row {
            options.forEach { option ->
                val isOn = option.value == selection
                Box(
                    modifier = Modifier
                        .width(each)
                        .height(40.dp)
                        .clip(RoundedCornerShape(9.dp))
                        .clickable(role = Role.Tab) { onSelect(option.value) }
                        .semantics { selected = isOn },
                    contentAlignment = Alignment.Center,
                ) {
                    KText(
                        option.label,
                        KTextStyle(size = 14f, weight = if (isOn) FontWeight.SemiBold else FontWeight.Medium),
                        color = if (isOn) KColors.textPrimary else KColors.textSecondary, maxLines = 1,
                    )
                }
            }
        }
    }
}

/**
 * Tabs with an underline that slides under the selected one.
 *
 * When the tabs fit they share the full width; when they don't, the row
 * scrolls sideways and keeps the selected tab in view. [inset] pads the tabs
 * from the screen edges while the divider under them still runs the full width.
 */
@Composable
fun <T> KUnderlineTabs(
    tabs: List<KOption<T>>,
    selection: T,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier,
    inset: Dp = 0.dp,
    /** Tabs that get a small dot: something there needs attention. */
    badges: Set<T> = emptySet(),
) {
    val density = LocalDensity.current
    val scroll = rememberScrollState()
    val lefts = remember { mutableStateMapOf<Int, Dp>() }
    val widths = remember { mutableStateMapOf<Int, Dp>() }
    val selected = tabs.indexOfFirst { it.value == selection }.coerceAtLeast(0)
    BoxWithConstraints(modifier.fillMaxWidth().padding(top = KSpace.sm)) {
        val viewport = maxWidth
        val minTab = if (tabs.isEmpty()) 0.dp else (maxWidth - inset * 2).coerceAtLeast(0.dp) / tabs.size
        // Keep the selected tab in view, centred when there's room to scroll.
        LaunchedEffect(selected, lefts[selected], widths[selected]) {
            val left = lefts[selected] ?: return@LaunchedEffect
            val width = widths[selected] ?: return@LaunchedEffect
            val centre = with(density) { (inset + left + width / 2 - viewport / 2).roundToPx() }
            scroll.animateScrollTo(centre.coerceIn(0, scroll.maxValue))
        }
        HorizontalDivider(Modifier.align(Alignment.BottomCenter), color = KColors.border)
        Box(Modifier.horizontalScroll(scroll).padding(horizontal = inset)) {
            Row {
                tabs.forEachIndexed { index, tab ->
                    val isOn = index == selected
                    Box(
                        modifier = Modifier
                            .widthIn(min = minTab)
                            .onGloballyPositioned {
                                with(density) {
                                    lefts[index] = it.positionInParent().x.toDp()
                                    widths[index] = it.size.width.toDp()
                                }
                            }
                            .clickable(
                                role = Role.Tab, indication = null,
                                interactionSource = remember { MutableInteractionSource() },
                            ) { onSelect(tab.value) }
                            .semantics { this.selected = isOn }
                            .padding(horizontal = KSpace.md)
                            .padding(bottom = 12.5.dp, top = KSpace.xs),
                        contentAlignment = Alignment.Center,
                    ) {
                        KText(
                            tab.label, KTextToken.bodyStrong,
                            color = if (isOn) KColors.brand else KColors.textSecondary,
                            maxLines = 1, textAlign = TextAlign.Center,
                        )
                        if (tab.value in badges) {
                            Box(
                                Modifier.align(Alignment.TopEnd).offset(x = 2.dp, y = 2.dp).size(7.dp)
                                    .background(KColors.warning, CircleShape).clearAndSetSemantics {},
                            )
                        }
                    }
                }
            }
            val x by animateDpAsState(lefts[selected] ?: 0.dp, tween(280), label = "underlineX")
            val w by animateDpAsState(widths[selected] ?: 0.dp, tween(280), label = "underlineW")
            Box(
                Modifier.align(Alignment.BottomStart).offset(x = x).width(w).height(2.5.dp)
                    .background(KColors.brand, CircleShape),
            )
        }
    }
}
