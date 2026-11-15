package com.brixel.kameti.feature.shell

import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.compose.rememberLauncherForActivityResult
import android.os.Build
import android.Manifest
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.brixel.kameti.core.attempt
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
import com.brixel.kameti.ui.KLiveUpdates
import com.brixel.kameti.ui.KTabBar
import com.brixel.kameti.ui.KTabItem
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.MainScope

/**
 * The signed-in frame: Home, Inbox and Profile, each with its own stack of
 * screens. The system Back button goes back one screen, then to Home, then
 * leaves the app.
 */
@Composable
internal fun MainTabs(router: AppRouter, userId: String, dependencies: KametiDependencies, settings: ShellSettings) {
    val state by router.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    // Outlives this screen, so the live connection still closes after sign-out.
    val stopping = remember { MainScope() }
    // Shared by the Inbox tab and its badge, which is current from the first launch.
    val inboxModel: InboxViewModel = viewModel(key = "inbox-$userId") { InboxViewModel(userId, dependencies) }
    val inbox by inboxModel.state.collectAsStateWithLifecycle()
    LaunchedEffect(inboxModel) { inboxModel.load() }
    // Shared by the Profile tab and the screens it pushes.
    val profileModel: ProfileViewModel = viewModel(key = "profile-$userId") { ProfileViewModel(userId, dependencies) }
    val profile by profileModel.state.collectAsStateWithLifecycle()
    var askingName by remember { mutableStateOf(false) }
    // After sign-in: save the profile and settings on the phone (no-op once
    // saved), and ask for a name if Apple or Google didn't give one.
    LaunchedEffect(profileModel) {
        profileModel.load()
        if (profileModel.needsNamePrompt) {
            delay(600)
            askingName = true
        }
    }
    val tabs = listOf(
        AppTab.Home to KTabItem(stringResource(R.string.shell_home), KIcons.home),
        AppTab.Inbox to KTabItem(stringResource(R.string.shell_inbox), KIcons.inbox, badge = inbox.badgeCount),
        AppTab.Profile to KTabItem(stringResource(R.string.shell_profile), KIcons.person),
    )

    val entries = rememberRouteEntryScope(state, userId)
    // Shared by Home, the archived list and the screens that reload Home when they finish.
    val homeModel: HomeViewModel = viewModel(key = "home-$userId") { HomeViewModel(userId, dependencies) }

    // Live updates (FR-86-adjacent): screens refresh themselves.
    val live = KLiveUpdates.shared
    DisposableEffect(dependencies) {
        val listening = scope.launch {
            dependencies.live.start { change -> scope.launch { live.record(change.kametiId) } }
        }
        onDispose {
            listening.cancel()
            stopping.launch { dependencies.live.stop() }
        }
    }
    LaunchedEffect(live.revision) {
        if (live.revision > 0) {
            homeModel.refresh()
            inboxModel.refresh()
        }
    }
    // Push: save this phone's token for the signed-in account whenever it appears or changes.
    LaunchedEffect(dependencies) {
        PushCenter.token.collect { token ->
            if (token != null) attempt { dependencies.notifications.registerDevice(token, "android") }
        }
    }
    // A tapped notification: requests and invitations open the Inbox, the rest open their kameti.
    LaunchedEffect(router) {
        PushCenter.pendingTap.collect { tap ->
            if (tap == null) return@collect
            PushCenter.pendingTap.value = null
            inboxModel.refresh()
            when (val destination = tap.destination) {
                PushTap.Destination.Inbox -> router.tab = AppTab.Inbox
                is PushTap.Destination.Kameti -> {
                    router.tab = AppTab.Home
                    router.homePath = listOf(Route.KametiDetail(destination.id))
                }
            }
        }
    }
    // Ask once, soon after signing in (board AN-4): members need it as much as
    // owners, and many join before they have any kameti of their own.
    val context = LocalContext.current
    var askingPush by remember { mutableStateOf(false) }
    val pushPermission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {}
    LaunchedEffect(askingName) {
        val canAsk = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !notificationsAllowed(context)
        // The push prompt waits until the name prompt is closed.
        if (!canAsk || PushCenter.hasAsked || askingName) return@LaunchedEffect
        delay(1_500)
        if (!profileModel.needsNamePrompt) askingPush = true
    }

    // Back in the app after being away: catch up on anything missed.
    var wasStopped by remember { mutableStateOf(false) }
    LifecycleStartEffect(Unit) {
        if (wasStopped) live.refreshAll()
        onStopOrDispose { wasStopped = true }
    }

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
                        TabRoot(entry.tab, router, homeModel, inboxModel, profileModel, settings, userId)
                    } else {
                        RouteDestination(route, router, userId, dependencies, homeModel, inboxModel, profileModel)
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

    if (askingPush) {
        PushPermissionSheet(
            onAllow = {
                PushCenter.hasAsked = true
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) pushPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
            },
            onDismiss = {
                askingPush = false
                PushCenter.hasAsked = true
            },
        )
    }
    if (askingName) {
        EditNameSheet(
            title = stringResource(R.string.shell_what_should_we_call_you),
            current = profile.profile?.displayName.orEmpty(),
            startsEmpty = profile.nameIsPlaceholder,
            save = { profileModel.updateName(it) },
            // Closed by Save or a swipe: don't ask again on this sign-in.
            onDismiss = {
                askingName = false
                profileModel.markNamePrompted()
            },
            allowsUnchanged = true,
        )
    }
}

/** The first screen of a tab. Each phase of the port replaces one of these. */
@Composable
private fun TabRoot(
    tab: AppTab,
    router: AppRouter,
    homeModel: HomeViewModel,
    inboxModel: InboxViewModel,
    profileModel: ProfileViewModel,
    settings: ShellSettings,
    userId: String,
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
        AppTab.Profile -> {
            val context = LocalContext.current
            var notificationsOn by remember { mutableStateOf(notificationsAllowed(context)) }
            // Back from the notification settings (ours or the phone's): show the new state.
            LifecycleResumeEffect(Unit) {
                notificationsOn = notificationsAllowed(context)
                onPauseOrDispose {}
            }
            ProfileScreen(
                model = profileModel,
                settings = settings,
                notificationsOn = notificationsOn,
                onOpenNotifications = { router.push(Route.NotificationSettings) },
                onOpenPeople = { router.push(Route.MyPeople) },
                onOpenPast = { router.push(Route.PastKametis) },
            )
        }
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
    profileModel: ProfileViewModel,
) {
    // After archiving: the kameti has left the live list, so show Home, reloaded.
    val goHome = {
        router.popToRoot()
        router.tab = AppTab.Home
        homeModel.refresh()
    }
    when (route) {
        // Its view model lives in this stack entry, so it lasts as long as the screen is pushed.
        is Route.KametiDetail -> KametiDetailScreen(
            model = viewModel { KametiDetailViewModel(route.id, userId, dependencies, preview = homeModel.kameti(route.id)) },
            onBack = { router.pop() },
            onResumeDraft = { router.push(Route.ResumeDraft(it)) },
            onOpenActivity = { router.push(Route.Activity(it)) },
            onArchived = goHome,
        )
        is Route.KametiMembers -> KametiDetailScreen(
            model = viewModel {
                KametiDetailViewModel(route.id, userId, dependencies, preview = homeModel.kameti(route.id), opensOnMembers = true)
            },
            onBack = { router.pop() },
            onResumeDraft = { router.push(Route.ResumeDraft(it)) },
            onOpenActivity = { router.push(Route.Activity(it)) },
            onArchived = goHome,
        )
        // Opened straight into a recording action (Home's Record payment).
        is Route.KametiAction -> KametiDetailScreen(
            model = viewModel {
                KametiDetailViewModel(route.id, userId, dependencies, homeModel.kameti(route.id), route.action)
            },
            onBack = { router.pop() },
            onResumeDraft = { router.push(Route.ResumeDraft(it)) },
            onOpenActivity = { router.push(Route.Activity(it)) },
            onArchived = goHome,
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
        Route.PastKametis -> {
            val profile by profileModel.state.collectAsStateWithLifecycle()
            LaunchedEffect(Unit) { profileModel.load() }
            PastKametisScreen(profile.pastKametis, onBack = { router.pop() }, onOpen = { router.push(Route.KametiDetail(it)) })
        }
        Route.MyPeople -> {
            val profile by profileModel.state.collectAsStateWithLifecycle()
            PeopleScreen(profile.people, onBack = { router.pop() })
        }
        Route.NotificationSettings -> NotificationSettingsScreen(userId, dependencies, onBack = { router.pop() })
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
            // Straight to Members, so the owner can invite people right away.
            router.homePath = listOf(Route.KametiMembers(id))
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
