package com.brixel.kameti.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider

/**
 * Wraps the app: provides the Kameti colour tokens for the chosen appearance
 * and maps them onto Material 3, so any Material control that shows through
 * (ripples, text selection, system sheets) still uses Kameti colours.
 */
@Composable
fun KTheme(dark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val k = if (dark) KDarkColors else KLightColors
    val base = if (dark) darkColorScheme() else lightColorScheme()
    val material = base.copy(
        primary = k.brand,
        onPrimary = k.textOnBrand,
        primaryContainer = k.brandSubtle,
        onPrimaryContainer = k.onBrandSubtle,
        secondary = k.brand,
        onSecondary = k.textOnBrand,
        background = k.background,
        onBackground = k.textPrimary,
        surface = k.surface,
        onSurface = k.textPrimary,
        surfaceVariant = k.surfaceSunken,
        onSurfaceVariant = k.textSecondary,
        surfaceContainer = k.surface,
        surfaceContainerLow = k.surface,
        surfaceContainerHigh = k.surface,
        outline = k.borderStrong,
        outlineVariant = k.border,
        error = k.negative,
        errorContainer = k.negativeSubtle,
        scrim = k.overlay,
    )
    CompositionLocalProvider(LocalKColors provides k) {
        MaterialTheme(colorScheme = material, content = content)
    }
}
