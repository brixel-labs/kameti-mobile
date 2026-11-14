package com.brixel.kameti.feature.shell

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import com.brixel.kameti.ui.KAppearance

/**
 * The home-screen icons the app ships. Each is a launcher entry in the app's
 * manifest; the previews are images in this module, because another
 * module's launcher icon can't be loaded here.
 */
enum class KAppIcon(@param:StringRes val title: Int, @param:StringRes val detail: Int, @param:DrawableRes val preview: Int) {
    Circle(R.string.shell_circle, R.string.shell_the_default, R.drawable.shell_icon_circle),
    Midnight(R.string.shell_midnight, R.string.shell_deep_green_glowing_mint, R.drawable.shell_icon_midnight),
    Monogram(R.string.shell_k, R.string.shell_just_the_letter, R.drawable.shell_icon_monogram),
    Turns(R.string.shell_turns, R.string.shell_the_pot_one_turn_lit, R.drawable.shell_icon_turns),
}

/** Changes the app's home-screen icon. The app module provides it. */
interface AppIconSwitcher {
    val current: KAppIcon

    /** `false` when the icon couldn't be changed. */
    fun select(icon: KAppIcon): Boolean
}

/** What Profile's settings need from the app module: the look and the icon. */
class ShellSettings(
    val appearance: KAppearance = KAppearance.System,
    val onAppearance: (KAppearance) -> Unit = {},
    /** `null` hides the App icon row. */
    val appIcons: AppIconSwitcher? = null,
)
