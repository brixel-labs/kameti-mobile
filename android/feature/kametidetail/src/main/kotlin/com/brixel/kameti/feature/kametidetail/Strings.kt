package com.brixel.kameti.feature.kametidetail

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext

/**
 * Looks up a string resource and fills in its arguments. Logic that builds
 * sentences (activity rows, note labels) takes one of these, so it stays
 * testable: the app passes the real resources, tests pass the English text.
 */
internal typealias Strings = (id: Int, args: Array<out Any>) -> String

internal fun Strings.get(id: Int, vararg args: Any): String = this(id, args)

@Composable
internal fun rememberStrings(): Strings {
    val context = LocalContext.current
    return remember(context) { { id, args -> context.getString(id, *args) } }
}
