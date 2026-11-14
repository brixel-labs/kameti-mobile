package com.brixel.kameti.ui

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp

/**
 * A text style from the design tokens. The size is in sp and scales with the
 * user's font size.
 */
@Immutable
data class KTextStyle(
    val size: Float,
    val weight: FontWeight,
    val tracking: Float = 0f,
    /** Fixed-width digits, so amounts line up in columns. */
    val tabular: Boolean = false,
) {
    fun toTextStyle(): TextStyle = TextStyle(
        fontSize = size.sp,
        fontWeight = weight,
        letterSpacing = tracking.sp,
        fontFeatureSettings = if (tabular) "tnum" else null,
    )
}

/**
 * Text in a design-token style: `KText("Title", KTextToken.title)`. The only
 * way feature code draws text.
 */
@Composable
fun KText(
    text: String,
    style: KTextStyle,
    modifier: Modifier = Modifier,
    color: Color = KColors.textPrimary,
    textAlign: TextAlign? = null,
    maxLines: Int = Int.MAX_VALUE,
    overflow: TextOverflow = TextOverflow.Ellipsis,
) {
    Text(
        text = text,
        modifier = modifier,
        style = style.toTextStyle(),
        color = color,
        textAlign = textAlign,
        maxLines = maxLines,
        overflow = overflow,
    )
}

/** Text with parts in different colours or weights ("This month: **Ali + Sara**"). */
@Composable
fun KText(
    text: AnnotatedString,
    style: KTextStyle,
    modifier: Modifier = Modifier,
    color: Color = KColors.textPrimary,
    maxLines: Int = Int.MAX_VALUE,
) {
    Text(
        text = text,
        modifier = modifier,
        style = style.toTextStyle(),
        color = color,
        maxLines = maxLines,
        overflow = TextOverflow.Ellipsis,
    )
}
