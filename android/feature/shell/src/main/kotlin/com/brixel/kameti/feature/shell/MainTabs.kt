package com.brixel.kameti.feature.shell

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.feature.createkameti.CreateKametiScreen
import com.brixel.kameti.feature.createkameti.CreateWizardViewModel
import com.brixel.kameti.feature.home.ArchivedKametisScreen
import com.brixel.kameti.feature.home.HomeScreen
import com.brixel.kameti.feature.home.HomeViewModel
import com.brixel.kameti.feature.invites.InboxScreen
import com.brixel.kameti.feature.invites.InboxViewModel
import com.brixel.kameti.feature.invites.JoinInviteScreen
import com.brixel.kameti.feature.invites.JoinInviteViewModel
import com.brixel.kameti.feature.kametidetail.ActivityScreen
import com.brixel.kameti.feature.kametidetail.ActivityViewModel
import com.brixel.kameti.feature.kametidetail.KametiDetailScreen
import com.brixel.kameti.feature.kametidetail.KametiDetailViewModel
import com.brixel.kameti.navigation.AppRouter
import com.brixel.kameti.navigation.AppTab
import com.brixel.kameti.navigation.Route
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KTabBar
import com.brixel.kameti.ui.KTabItem

/**
 * The signed-in frame: Home, Inbox and Profile, each with its own stack of
 * screens. The system Back button goes back one screen, then to Home, then
 * leaves the app.
 */
@Composable
internal fun MainTabs(router: AppRouter, userId: String, dependencies: KametiDependencies) {
    val state by router.state.collectAsStateWithLifecycle()
    // Shared by the Inbox tab and its badge, which is current from the first launch.
    val inboxModel: InboxViewModel = viewModel(key = "inbox-$userId") { InboxViewModel(userId, dependencies) }
    val inbox by inboxModel.state.collectAsStateWithLifecycle()
    LaunchedEffect(inboxModel) { inboxModel.load() }
    val tabs = listOf(
        AppTab.Home to KTabItem(stringResource(R.string.shell_home), KIcons.home),
        AppTab.Inbox to KTabItem(stringResource(R.string.shell_inbox), KIcons.inbox, badge = inbox.badgeCount),
        AppTab.Profile to KTabItem(stringResource(R.string.shell_profile), KIcons.person),
    )

    val entries = rememberRouteEntryScope(state, userId)
    // Shared by Home, the archived list and the screens that reload Home when they finish.
    val homeModel: HomeViewModel = viewModel(key = "home-$userId") { HomeViewModel(userId, dependencies) }

    BackHandler(enabled = state.currentPath.isNotEmpty() || state.tab != AppTab.Home) {
        if (!router.pop()) router.tab = AppTab.Home
    }

    Column(Modifier.fillMaxSize().background(KColors.background)) {
        Box(Modifier.weight(1f).statusBarsPadding()) {
            AnimatedContent(
                targetState = state.currentEntry(),
                contentKey = { it.key },
                transitionSpec = { fadeIn() togetherWith fadeOut() },
                label = "route",
            ) { entry ->
                entries.Entry(entry) {
                    val route = entry.route
                    if (route == null) {
                        TabRoot(entry.tab, router, userId, dependencies, homeModel, inboxModel)
                    } else {
                        RouteDestination(route, router, userId, dependencies, homeModel, inboxModel, title = tabs.first { it.first == entry.tab }.second.title)
                    }
                }
            }
        }
        // The create wizard takes the whole screen, like on iOS: its own
        // buttons sit where the tabs were.
        val route = state.currentPath.lastOrNull()
        if (route != Route.CreateKameti && route !is Route.ResumeDraft) KTabBar(
            items = tabs.map { it.second },
            selectedIndex = tabs.indexOfFirst { it.first == state.tab },
            onSelect = { index ->
                val tab = tabs[index].first
                // Tapping the tab you are on goes back to its first screen.
                if (tab == state.tab) router.popToRoot() else router.tab = tab
            },
        )
    }
}

/** The first screen of a tab. Each phase of the port replaces one of these. */
@Composable
private fun TabRoot(
    tab: AppTab,
    router: AppRouter,
    userId: String,
    dependencies: KametiDependencies,
    homeModel: HomeViewModel,
    inboxModel: InboxViewModel,
) {
    when (tab) {
        AppTab.Home -> HomeScreen(
            model = homeModel,
            // A draft reopens the wizard where it was left. Only the owner
            // edits a draft; a member sees it as "being updated".
            onOpen = { id ->
                val kameti = homeModel.kameti(id)
                val resumes = kameti?.status == KametiStatus.Draft && kameti.isOwnedBy(userId)
                router.push(if (resumes) Route.ResumeDraft(id) else Route.KametiDetail(id))
            },
            onRecord = { id, action -> router.push(Route.KametiAction(id, action)) },
            onCreate = { router.push(Route.CreateKameti) },
            onJoin = { router.push(Route.Join(it)) },
            onOpenInvitation = { router.push(Route.Invitation(it)) },
            onOpenArchived = { router.push(Route.ArchivedKametis) },
        )
        AppTab.Inbox -> InboxScreen(
            model = inboxModel,
            onOpenInvitation = { router.push(Route.Invitation(it)) },
            onOpenKameti = { router.push(Route.KametiDetail(it)) },
        )
        AppTab.Profile -> ProfileComingNext(userId, dependencies)
    }
}

/** Maps a route to the screen that draws it. Later phases add their screens here. */
@Composable
private fun RouteDestination(
    route: Route,
    router: AppRouter,
    userId: String,
    dependencies: KametiDependencies,
    homeModel: HomeViewModel,
    inboxModel: InboxViewModel,
    title: String,
) {
    when (route) {
        // Its view model lives in this stack entry, so it lasts as long as the screen is pushed.
        is Route.KametiDetail -> KametiDetailScreen(
            model = viewModel { KametiDetailViewModel(route.id, userId, dependencies, preview = homeModel.kameti(route.id)) },
            onBack = { router.pop() },
            onResumeDraft = { router.push(Route.ResumeDraft(it)) },
            onOpenActivity = { router.push(Route.Activity(it)) },
        )
        // Opened straight into a recording action (Home's Record payment).
        is Route.KametiAction -> KametiDetailScreen(
            model = viewModel {
                KametiDetailViewModel(route.id, userId, dependencies, homeModel.kameti(route.id), route.action)
            },
            onBack = { router.pop() },
            onResumeDraft = { router.push(Route.ResumeDraft(it)) },
            onOpenActivity = { router.push(Route.Activity(it)) },
        )
        Route.ArchivedKametis -> ArchivedKametisScreen(
            model = homeModel,
            onBack = { router.pop() },
            onOpen = { router.push(Route.KametiDetail(it)) },
        )
        Route.CreateKameti -> CreateWizard(router, userId, dependencies, homeModel, draftId = null)
        is Route.ResumeDraft -> CreateWizard(router, userId, dependencies, homeModel, draftId = route.id)
        is Route.Join -> JoinInvite(router, dependencies, homeModel, inboxModel, token = route.token, inviteId = null)
        is Route.Invitation -> JoinInvite(router, dependencies, homeModel, inboxModel, token = null, inviteId = route.id)
        is Route.Activity -> ActivityScreen(
            model = viewModel { ActivityViewModel(route.kametiId, userId, dependencies) },
            onBack = { router.pop() },
        )
        Route.PastKametis,
        -> ComingNext(title, onBack = { router.pop() })
    }
}

/**
 * The create wizard, new or reopened on a saved draft. Closing keeps the
 * draft (it is on the server); starting opens the new kameti. Either way
 * Home reloads, so the draft or the running kameti shows there.
 */
@Composable
private fun CreateWizard(
    router: AppRouter,
    userId: String,
    dependencies: KametiDependencies,
    homeModel: HomeViewModel,
    draftId: String?,
) {
    CreateKametiScreen(
        model = viewModel { CreateWizardViewModel(userId, dependencies) },
        onStarted = { id ->
            homeModel.refresh()
            router.homePath = listOf(Route.KametiDetail(id))
        },
        onClose = {
            homeModel.refresh()
            router.popToRoot()
        },
        draftId = draftId,
    )
}

/**
 * Accepting an invite, from a link or code (token) or from Home or Inbox
 * (invite id). Joining opens the kameti on Home; either way Home and the
 * Inbox reload, so the invitation leaves both.
 */
@Composable
private fun JoinInvite(
    router: AppRouter,
    dependencies: KametiDependencies,
    homeModel: HomeViewModel,
    inboxModel: InboxViewModel,
    token: String?,
    inviteId: String?,
) {
    val finished = {
        homeModel.refresh()
        inboxModel.refresh()
    }
    JoinInviteScreen(
        model = viewModel { JoinInviteViewModel(token, inviteId, dependencies) },
        onJoined = { id ->
            finished()
            router.inboxPath = emptyList()
            router.tab = AppTab.Home
            router.homePath = listOf(Route.KametiDetail(id))
        },
        onClose = {
            finished()
            router.popToRoot()
        },
        onBack = { router.pop() },
    )
}
