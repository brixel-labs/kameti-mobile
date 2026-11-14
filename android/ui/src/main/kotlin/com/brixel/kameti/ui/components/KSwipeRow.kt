package com.brixel.kameti.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import kotlin.math.roundToInt
import kotlinx.coroutines.launch

/** One round action revealed by swiping a [KSwipeRow] left. */
class KSwipeAction(val label: String, val icon: ImageVector, val tint: Color, val action: () -> Unit)

/**
 * A card that slides left to reveal round action buttons beside it. It snaps
 * open or shut, and tapping an action closes it first. Rows that share
 * [openRow] open one at a time: sliding one open closes the others, and
 * setting it to `null` (a tap elsewhere, a tab change) closes whichever is open.
 */
@Composable
fun KSwipeRow(
    id: String,
    openRow: String?,
    onOpenRowChange: (String?) -> Unit,
    actions: List<KSwipeAction>,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val density = LocalDensity.current
    val scope = rememberCoroutineScope()
    // How far the row slides: the buttons, the gaps between them and before them.
    val reveal = with(density) { ((52 + 12) * actions.size + 4).dp.toPx() }
    val offset = remember { Animatable(0f) }
    LaunchedEffect(openRow) { if (openRow != id && offset.value != 0f) offset.animateTo(0f) }

    fun settle(open: Boolean) {
        scope.launch { offset.animateTo(if (open) -reveal else 0f) }
        if (open && openRow != id) onOpenRowChange(id)
        if (!open && openRow == id) onOpenRowChange(null)
    }

    Box(
        modifier = modifier.semantics {
            // Screen readers get the same actions without swiping.
            customActions = actions.map { item -> CustomAccessibilityAction(item.label) { item.action(); true } }
        },
        contentAlignment = Alignment.CenterEnd,
    ) {
        Row(Modifier.padding(end = KSpace.xs), horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
            actions.forEach { item ->
                Box(
                    modifier = Modifier
                        .size(52.dp)
                        .clip(CircleShape)
                        .background(item.tint)
                        .clickable(enabled = offset.value < -1f, role = Role.Button) { settle(false); item.action() },
                    contentAlignment = Alignment.Center,
                ) {
                    // Readable on the tint in both looks (dark mode's tints are light).
                    KIcon(item.icon, tint = KColors.textOnBrand, size = 22.dp, label = item.label)
                }
            }
        }
        Box(
            modifier = Modifier
                .offset { IntOffset(offset.value.roundToInt(), 0) }
                .draggable(
                    orientation = Orientation.Horizontal,
                    state = rememberDraggableState { delta ->
                        scope.launch { offset.snapTo((offset.value + delta).coerceIn(-reveal, 0f)) }
                    },
                    onDragStopped = { velocity ->
                        settle(open = if (kotlin.math.abs(velocity) > 600f) velocity < 0 else offset.value < -reveal / 2)
                    },
                ),
        ) {
            content()
        }
    }
}
