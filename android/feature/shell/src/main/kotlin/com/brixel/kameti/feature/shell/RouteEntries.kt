package com.brixel.kameti.feature.shell

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.SaveableStateHolder
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.viewmodel.compose.LocalViewModelStoreOwner
import androidx.lifecycle.viewmodel.compose.viewModel
import com.brixel.kameti.navigation.AppTab
import com.brixel.kameti.navigation.RouterState

/**
 * One entry of a tab's stack: the tab's first screen (`index` 0) or a pushed
 * route. Its [key] names its saved state and its view models.
 */
internal data class RouteEntry(val tab: AppTab, val index: Int, val route: com.brixel.kameti.navigation.Route?) {
    val key: String get() = "$tab/$index/${route ?: "root"}"
}

/** Every entry currently on a stack, the first screens included. */
internal fun RouterState.entries(): List<RouteEntry> = AppTab.entries.flatMap { tab ->
    listOf(RouteEntry(tab, 0, null)) + path(tab).mapIndexed { index, route -> RouteEntry(tab, index + 1, route) }
}

/** The entry on screen: the top of the selected tab's stack. */
internal fun RouterState.currentEntry(): RouteEntry =
    RouteEntry(tab, currentPath.size, currentPath.lastOrNull())

/**
 * Keeps one `ViewModelStore` per stack entry, so a screen's view model lives
 * exactly as long as the screen is on its stack: it survives a rotation and
 * a visit to another tab, and is cleared when the screen is popped.
 */
internal class RouteEntryStores : ViewModel() {
    private val stores = mutableMapOf<String, ViewModelStore>()

    fun owner(key: String): ViewModelStoreOwner {
        val store = stores.getOrPut(key) { ViewModelStore() }
        return object : ViewModelStoreOwner {
            override val viewModelStore: ViewModelStore = store
        }
    }

    /** Clears the view models of entries that left their stack. */
    fun retain(keys: Set<String>) {
        val gone = stores.keys.filter { it !in keys }
        for (key in gone) stores.remove(key)?.clear()
    }

    override fun onCleared() {
        stores.values.forEach { it.clear() }
        stores.clear()
    }
}

/**
 * Gives each stack entry its own saved state and view models, and drops both
 * for entries that were popped. Create it once, outside any animation, so
 * the state of the other tabs is kept while they are off screen.
 */
internal class RouteEntryScope(private val stores: RouteEntryStores, private val saved: SaveableStateHolder) {
    @Composable
    fun Entry(entry: RouteEntry, content: @Composable () -> Unit) {
        val owner = remember(entry.key) { stores.owner(entry.key) }
        saved.SaveableStateProvider(entry.key) {
            CompositionLocalProvider(LocalViewModelStoreOwner provides owner, content = content)
        }
    }
}

@Composable
internal fun rememberRouteEntryScope(state: RouterState, userId: String): RouteEntryScope {
    val stores: RouteEntryStores = viewModel(key = "route-entries-$userId")
    val saved = rememberSaveableStateHolder()
    val live = remember(state) { state.entries().map { it.key }.toSet() }
    val known = remember { mutableSetOf<String>() }
    LaunchedEffect(live) {
        stores.retain(live)
        for (key in known - live) saved.removeState(key)
        known.retainAll(live)
        known.addAll(live)
    }
    return remember(stores, saved) { RouteEntryScope(stores, saved) }
}
