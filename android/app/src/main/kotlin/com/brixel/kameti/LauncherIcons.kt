package com.brixel.kameti

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import com.brixel.kameti.feature.shell.AppIconSwitcher
import com.brixel.kameti.feature.shell.KAppIcon

/**
 * Switches the home-screen icon by enabling one of the manifest's launcher
 * entries (`activity-alias`) and disabling the others. The launcher picks
 * the change up after a moment.
 */
class LauncherIcons(context: Context) : AppIconSwitcher {
    private val packageName = context.packageName
    private val packages = context.packageManager

    private fun component(icon: KAppIcon) = ComponentName(packageName, "$packageName.Icon${icon.name}")

    override val current: KAppIcon
        get() = KAppIcon.entries.firstOrNull { icon ->
            when (packages.getComponentEnabledSetting(component(icon))) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
                // Untouched: only the default icon's entry starts enabled.
                PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> icon == KAppIcon.Circle
                else -> false
            }
        } ?: KAppIcon.Circle

    override fun select(icon: KAppIcon): Boolean = try {
        // The new one on first, so there is never a moment with no launcher entry.
        setEnabled(icon, true)
        for (other in KAppIcon.entries) if (other != icon) setEnabled(other, false)
        true
    } catch (_: RuntimeException) {
        false
    }

    private fun setEnabled(icon: KAppIcon, enabled: Boolean) {
        val state = if (enabled) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        packages.setComponentEnabledSetting(component(icon), state, PackageManager.DONT_KILL_APP)
    }
}
