package com.brixel.kameti.navigation

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/** What the router shows: the selected tab and one stack of routes per tab. */
data class RouterState(
    val tab: AppTab = AppTab.Home,
    val homePath: List<Route> = emptyList(),
    val inboxPath: List<Route> = emptyList(),
    val profilePath: List<Route> = emptyList(),
) {
    fun path(tab: AppTab): List<Route> = when (tab) {
        AppTab.Home -> homePath
        AppTab.Inbox -> inboxPath
        AppTab.Profile -> profilePath
    }

    /** The selected tab's stack. */
    val currentPath: List<Route> get() = path(tab)

    fun withPath(tab: AppTab, path: List<Route>): RouterState = when (tab) {
        AppTab.Home -> copy(homePath = path)
        AppTab.Inbox -> copy(inboxPath = path)
        AppTab.Profile -> copy(profilePath = path)
    }
}

/**
 * Navigation state for the signed-in app: the selected tab and one stack per
 * tab. Plain state, so tests drive it directly and the screens just collect
 * [state].
 */
class AppRouter {
    private val current = MutableStateFlow(RouterState())
    val state: StateFlow<RouterState> = current.asStateFlow()

    var tab: AppTab
        get() = current.value.tab
        set(value) = current.update { it.copy(tab = value) }

    var homePath: List<Route>
        get() = current.value.homePath
        set(value) = current.update { it.copy(homePath = value) }

    var inboxPath: List<Route>
        get() = current.value.inboxPath
        set(value) = current.update { it.copy(inboxPath = value) }

    var profilePath: List<Route>
        get() = current.value.profilePath
        set(value) = current.update { it.copy(profilePath = value) }

    /** Pushes onto the current tab's stack. */
    fun push(route: Route) = current.update { it.withPath(it.tab, it.currentPath + route) }

    /** Goes back one screen on the current tab. `false` when it is already on its first screen. */
    fun pop(): Boolean {
        var popped = false
        current.update { state ->
            popped = state.currentPath.isNotEmpty()
            if (popped) state.withPath(state.tab, state.currentPath.dropLast(1)) else state
        }
        return popped
    }

    /** Pops the current tab's stack back to its first screen. */
    fun popToRoot() = current.update { it.withPath(it.tab, emptyList()) }

    /** Shows several changes (tab and stacks) as one step. */
    fun update(change: (RouterState) -> RouterState) = current.update(change)

    /**
     * Opens a link (an invite, say) on the Home tab. Returns whether the URL
     * was one we handle.
     */
    fun open(url: String): Boolean {
        val route = DeepLink.route(url) ?: return false
        current.update { it.copy(tab = AppTab.Home, homePath = listOf(route)) }
        return true
    }
}
