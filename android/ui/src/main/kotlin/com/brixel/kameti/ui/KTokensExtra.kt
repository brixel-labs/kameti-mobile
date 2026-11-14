package com.brixel.kameti.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// Tokens the design uses that aren't in tokens.json yet. They match the
// hand-written extensions in the iOS KametiUI (KDynamicColor.swift).

private val isDark: Boolean
    @Composable @ReadOnlyComposable get() = LocalKColors.current === KDarkColors

/**
 * Secondary text one step stronger than `textSecondary`, for subtitles
 * and captions under titles, so they stay readable at small sizes.
 */
val KColors.textSubtitle: Color
    @Composable @ReadOnlyComposable get() = if (isDark) Color(0xFFBCC8C3) else Color(0xFF33413B)

/** Dark green for the title of a paid-out strip. */
val KColors.positiveDeep: Color
    @Composable @ReadOnlyComposable get() = if (isDark) Color(0xFF7ADBA8) else Color(0xFF135C38)

/** Dark green for the subtitle of a paid-out strip. */
val KColors.positiveDeepSubtitle: Color
    @Composable @ReadOnlyComposable get() = if (isDark) Color(0xFF9FD9BC) else Color(0xFF1F5F3F)

/** 13 sp medium, for a subtitle under a title. */
val KTextToken.subtitle: KTextStyle get() = KTextStyle(size = 13f, weight = FontWeight.Medium)

/** 12 sp medium, for a small caption under a title. */
val KTextToken.subtitleSmall: KTextStyle get() = KTextStyle(size = 12f, weight = FontWeight.Medium)

/** One height for every single-line control (field, stepper, select). */
val KSize.fieldHeight: Dp get() = 56.dp
