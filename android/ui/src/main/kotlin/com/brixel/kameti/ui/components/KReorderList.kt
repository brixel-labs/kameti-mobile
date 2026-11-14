package com.brixel.kameti.ui

import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex

/**
 * A vertically scrolling list the user can reorder: press and hold a row,
 * then drag; it lifts, the others move aside, and it settles on release.
 * Rows are identified by string ids; [onReorder] is called with the new order
 * when a move finishes.
 */
@Composable
fun KReorderList(
    ids: List<String>,
    onReorder: (List<String>) -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(horizontal = KSpace.gutter, vertical = KSpace.sm),
    row: @Composable (index: Int, id: String) -> Unit,
) {
    val list = rememberLazyListState()
    val haptics = LocalHapticFeedback.current
    // The order on screen: follows `ids`, except while a row is being dragged.
    var order by remember(ids) { mutableStateOf(ids) }
    var dragging by remember { mutableStateOf<String?>(null) }
    var dragOffset by remember { mutableFloatStateOf(0f) }
    val currentOrder by rememberUpdatedState(order)
    val commit by rememberUpdatedState(onReorder)

    LazyColumn(state = list, modifier = modifier, contentPadding = contentPadding) {
        itemsIndexed(order, key = { _, id -> id }) { index, id ->
            val isDragging = id == dragging
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .then(if (isDragging) Modifier else Modifier.animateItem())
                    .zIndex(if (isDragging) 1f else 0f)
                    .graphicsLayer { translationY = if (isDragging) dragOffset else 0f }
                    .padding(vertical = 4.dp)
                    .then(if (isDragging) Modifier.shadow(6.dp, androidx.compose.foundation.shape.RoundedCornerShape(KRadius.card)) else Modifier)
                    .pointerInput(id) {
                        detectDragGesturesAfterLongPress(
                            onDragStart = {
                                dragging = id
                                dragOffset = 0f
                                haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                            },
                            onDrag = { change, amount ->
                                change.consume()
                                dragOffset += amount.y
                                val items = list.layoutInfo.visibleItemsInfo
                                val me = items.firstOrNull { it.key == id } ?: return@detectDragGesturesAfterLongPress
                                val centre = me.offset + dragOffset + me.size / 2f
                                // Past the middle of a neighbour: swap places with it.
                                val target = items.firstOrNull { it.key != id && centre > it.offset && centre < it.offset + it.size }
                                if (target != null) {
                                    val from = currentOrder.indexOf(id)
                                    val to = currentOrder.indexOf(target.key as String)
                                    if (from >= 0 && to >= 0) {
                                        order = currentOrder.toMutableList().apply { add(to, removeAt(from)) }
                                        dragOffset += (me.offset - target.offset).toFloat()
                                    }
                                }
                            },
                            onDragEnd = {
                                dragging = null
                                dragOffset = 0f
                                if (currentOrder != ids) commit(currentOrder)
                            },
                            onDragCancel = {
                                dragging = null
                                dragOffset = 0f
                                order = ids
                            },
                        )
                    },
            ) {
                row(index, id)
            }
        }
    }
}
