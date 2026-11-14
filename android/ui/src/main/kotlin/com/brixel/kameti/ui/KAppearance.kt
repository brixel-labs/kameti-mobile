package com.brixel.kameti.ui

import androidx.annotation.StringRes

/**
 * The owner's choice of light, dark or following the system. Stored under
 * [STORAGE_KEY] and applied once at the root: `KTheme(dark = choice.isDark(systemDark))`.
 */
enum class KAppearance(val rawValue: String, @param:StringRes val titleRes: Int) {
    System("system", R.string.ui_system),
    Light("light", R.string.ui_light),
    Dark("dark", R.string.ui_dark);

    fun isDark(systemIsDark: Boolean): Boolean = when (this) {
        System -> systemIsDark
        Light -> false
        Dark -> true
    }

    companion object {
        const val STORAGE_KEY = "kameti.appearance"

        fun of(rawValue: String?): KAppearance = entries.firstOrNull { it.rawValue == rawValue } ?: System
    }
}
