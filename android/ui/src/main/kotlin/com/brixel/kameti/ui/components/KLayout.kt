package com.brixel.kameti.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex

/**
 * A flat card with a 1 dp border (direction A has no card shadows). With
 * [onClick] the whole card is tappable, not just a chevron inside it.
 */
@Composable
fun KCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    padding: PaddingValues = PaddingValues(KSpace.lg),
    content: @Composable ColumnScope.() -> Unit,
) {
    val shape = RoundedCornerShape(KRadius.card)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(KColors.surface)
            .border(1.dp, KColors.border, shape)
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(padding),
        content = content,
    )
}

/** An upper-cased section label with an optional action on the trailing side. */
@Composable
fun KSectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    actionTitle: String? = null,
    /** Adds a trailing chevron so the action reads as a link. */
    showsChevron: Boolean = false,
    action: (() -> Unit)? = null,
) {
    Row(
        modifier = modifier.fillMaxWidth().padding(vertical = KSpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KText(
            title.uppercase(), KTextToken.label, color = KColors.textSecondary,
            modifier = Modifier.semantics { heading() },
        )
        Spacer(Modifier.weight(1f))
        if (actionTitle != null && action != null) {
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(KRadius.sm))
                    .clickable(onClick = action)
                    .heightIn(min = KSize.minTouch),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(KSpace.xs),
            ) {
                KText(actionTitle, KTextToken.bodyStrong, color = KColors.brand)
                if (showsChevron) KIcon(KIcons.chevronRight, tint = KColors.brand, size = 18.dp)
            }
        }
    }
}

/** The three avatar sizes. */
enum class KAvatarSize(val dimension: Dp) { Small(30.dp), Medium(36.dp), Large(48.dp) }

/** One face in an avatar stack. */
data class KPerson(val name: String, val colorIndex: Int)

/** "Ali Raza" -> "AR", "Hassan" -> "H". */
fun initialsOf(name: String): String {
    val words = name.split(Regex("\\s+")).filter { it.isNotEmpty() }
    val letters = if (words.size >= 2) listOf(words.first(), words.last()) else words.take(1)
    return letters.joinToString("") { it.take(1).uppercase() }
}

/** A member's initials on their palette colour. Decorative. */
@Composable
fun KAvatar(name: String, colorIndex: Int, modifier: Modifier = Modifier, size: KAvatarSize = KAvatarSize.Medium) {
    val palette = KColors.avatar(colorIndex)
    Box(
        modifier = modifier.size(size.dimension).background(palette.background, CircleShape).clearAndSetSemantics {},
        contentAlignment = Alignment.Center,
    ) {
        KText(
            initialsOf(name), KTextStyle(size = size.dimension.value * 0.36f, weight = FontWeight.SemiBold),
            color = palette.foreground, maxLines = 1,
        )
    }
}

/**
 * Overlapping avatars, for "who receives this month". With [showsCheck], each
 * avatar gets a small green tick (already paid out). Up to [limit] faces;
 * with [showsOverflow], the rest show as a "+N" bubble.
 */
@Composable
fun KAvatarStack(
    people: List<KPerson>,
    modifier: Modifier = Modifier,
    showsCheck: Boolean = false,
    limit: Int = 3,
    showsOverflow: Boolean = false,
    size: KAvatarSize = KAvatarSize.Medium,
) {
    val overflow = if (showsOverflow) maxOf(people.size - limit, 0) else 0
    Row(modifier = modifier.clearAndSetSemantics {}, horizontalArrangement = Arrangement.spacedBy((-10).dp)) {
        people.take(limit).forEachIndexed { index, person ->
            Box(Modifier.zIndex(-index.toFloat())) {
                KAvatar(
                    person.name, person.colorIndex, size = size,
                    modifier = Modifier.border(2.dp, KColors.surface, CircleShape),
                )
                if (showsCheck) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .offset(2.dp, 2.dp)
                            .size(16.dp)
                            .background(KColors.brand, CircleShape)
                            .border(2.dp, KColors.surface, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        KIcon(KIcons.check, tint = KColors.textOnBrand, size = 10.dp)
                    }
                }
            }
        }
        if (overflow > 0) {
            Box(
                modifier = Modifier
                    .zIndex(-limit.toFloat())
                    .size(size.dimension)
                    .background(KColors.surfaceSunken, CircleShape)
                    .border(2.dp, KColors.surface, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                KText(
                    "+$overflow", KTextStyle(size = size.dimension.value * 0.33f, weight = FontWeight.SemiBold),
                    color = KColors.textSecondary,
                )
            }
        }
    }
}
