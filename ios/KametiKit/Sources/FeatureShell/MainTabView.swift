import FeatureCreateKameti
import FeatureHome
import FeatureInvites
import FeatureKametiDetail
import KametiCore
import KametiDomain
import KametiNavigation
import KametiUI
import SwiftUI

/// The signed-in frame: Home, Inbox and Profile. On iOS 26 `TabView` is the
/// system tab bar, so it gets Liquid Glass with no extra code.
struct MainTabView: View {
    @Bindable var router: AppRouter
    let userId: String
    let dependencies: KametiDependencies
    @State private var profileModel: ProfileViewModel
    @State private var homeModel: HomeViewModel
    @State private var inboxModel: InboxViewModel
    @State private var askingPush = false
    @State private var askingName = false
    /// The push prompt waits until the name prompt is closed.
    @State private var pushAfterName = false
    @State private var nameSheetHeight: CGFloat = 260
    @Environment(\.scenePhase) private var scenePhase
    private var push: PushCenter { .shared }

    init(router: AppRouter, userId: String, dependencies: KametiDependencies) {
        self.router = router
        self.userId = userId
        self.dependencies = dependencies
        _profileModel = State(initialValue: ProfileViewModel(userId: userId, dependencies: dependencies))
        _homeModel = State(initialValue: HomeViewModel(userId: userId, dependencies: dependencies))
        _inboxModel = State(initialValue: InboxViewModel(userId: userId, dependencies: dependencies))
    }

    var body: some View {
        TabView(selection: $router.tab) {
            Tab(value: AppTab.home) {
                NavigationStack(path: $router.homePath) {
                    HomeView(
                        model: homeModel,
                        // A draft reopens the wizard where it was left.
                        onOpen: { id in
                            // Only the owner edits a draft; a member sees it as "being updated".
                            let kameti = homeModel.kameti(id: id)
                            router.push(kameti?.status == .draft && kameti?.isOwned(by: userId) == true ? .resumeDraft(id: id) : .kametiDetail(id: id))
                        },
                        onRecord: { router.push(.kametiAction(id: $0, action: $1)) },
                        onCreate: { router.push(.createKameti) },
                        onJoin: { router.push(.join(token: $0)) },
                        onOpenInvitation: { router.push(.invitation(id: $0)) },
                        onOpenArchived: { router.push(.archivedKametis) }
                    )
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0, userId: userId, dependencies: dependencies, router: router, onFinished: { Task { await homeModel.load() } }, knownKameti: { homeModel.kameti(id: $0) }, homeModel: homeModel, profileModel: profileModel) }
                }
            } label: {
                Label(String(localized: "Home", bundle: .module), systemImage: "house")
            }

            Tab(value: AppTab.inbox) {
                NavigationStack(path: $router.inboxPath) {
                    InboxView(
                        model: inboxModel,
                        onOpenInvitation: { router.push(.invitation(id: $0)) },
                        onOpenKameti: { router.push(.kametiDetail(id: $0)) }
                    )
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0, userId: userId, dependencies: dependencies, router: router, onFinished: { Task { await homeModel.load() } }, knownKameti: { homeModel.kameti(id: $0) }, homeModel: homeModel, profileModel: profileModel) }
                }
            } label: {
                Label(String(localized: "Inbox", bundle: .module), systemImage: "tray")
            }
            .badge(inboxModel.badgeCount)

            Tab(value: AppTab.profile) {
                NavigationStack(path: $router.profilePath) {
                    ProfileView(model: profileModel, onOpenKameti: { router.push(.kametiDetail(id: $0)) }, onOpenPast: { router.push(.pastKametis) })
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0, userId: userId, dependencies: dependencies, router: router, onFinished: { Task { await homeModel.load() } }, knownKameti: { homeModel.kameti(id: $0) }, homeModel: homeModel, profileModel: profileModel) }
                }
            } label: {
                Label(String(localized: "Profile", bundle: .module), systemImage: "person")
            }
        }
        .tint(KColors.brand)
        // Keeps the Inbox badge current from the first launch.
        .task { await inboxModel.load() }
        // After sign-in: save the profile and settings on the phone (no-op once
        // saved), ask for a name if Apple or Google didn't give one, then push.
        .task {
            await profileModel.load()
            if profileModel.needsNamePrompt {
                try? await Task.sleep(for: .milliseconds(600))
                askingName = true
            }
            await startPush()
        }
        // Live updates (FR-86-adjacent): screens refresh themselves.
        .task {
            await dependencies.live.start { change in
                Task { @MainActor in KLiveUpdates.shared.record(kametiId: change.kametiId) }
            }
        }
        .onDisappear { Task { await dependencies.live.stop() } }
        .onChange(of: KLiveUpdates.shared.revision) {
            Task { await homeModel.load() }
            Task { await inboxModel.load() }
        }
        // Back in the app: catch up on anything missed while away.
        .onChange(of: scenePhase) { old, new in
            if new == .active, old == .background { KLiveUpdates.shared.refreshAll() }
        }
        .onChange(of: inboxModel.badgeCount) { _, count in push.setBadge(count) }
        .onChange(of: push.pendingTap) { _, tap in if let tap { open(tap) } }
        .kBottomSheet(
            isPresented: $askingName, title: String(localized: "What should we call you?", bundle: .module),
            detents: [.height(nameSheetHeight + 58)]
        ) {
            NamePromptSheet(
                current: profileModel.profile?.displayName ?? "", isPlaceholder: profileModel.nameIsPlaceholder,
                save: { await profileModel.updateName($0) }
            ) { askingName = false }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { nameSheetHeight = $0 }
        }
        // Closed by Save or a swipe: don't ask again on this sign-in, then push.
        .onChange(of: askingName) { _, open in
            guard !open else { return }
            profileModel.markNamePrompted()
            if pushAfterName {
                pushAfterName = false
                Task { try? await Task.sleep(for: .milliseconds(500)); askingPush = true }
            }
        }
        .kBottomSheet(isPresented: $askingPush, title: "", detents: [.large]) {
            PushPermissionSheet(
                onAllow: { askingPush = false; Task { await push.requestPermission() } },
                onLater: { askingPush = false; push.hasAsked = true }
            )
        }
    }

    /// Saves this phone's token for the signed-in account whenever it appears
    /// or changes, and registers with APNs if pushes are already allowed.
    private func startPush() async {
        let notifications = dependencies.notifications
        push.onToken = { token in
            guard let token else { return }
            Task { try? await notifications.registerDevice(token: token, platform: "ios") }
        }
        if let token = push.fcmToken { try? await notifications.registerDevice(token: token, platform: "ios") }
        await push.registerIfAllowed()
        if let tap = push.pendingTap { open(tap) }
        // Ask once, soon after signing in (board AN-4): members need it as much as
        // owners, and many join before they have any kameti of their own.
        if push.status == .notDetermined, !push.hasAsked {
            if askingName { pushAfterName = true; return }
            try? await Task.sleep(for: .seconds(1))
            askingPush = true
        }
    }

    /// A tapped notification: requests and invitations open the Inbox, the
    /// rest open their kameti.
    private func open(_ tap: PushTap) {
        push.pendingTap = nil
        Task { await inboxModel.load() }
        if !AppNotification.opensKameti(kind: tap.kind) || tap.kametiId == nil {
            router.tab = .inbox
        } else if let id = tap.kametiId {
            router.tab = .home
            router.homePath = [.kametiDetail(id: id)]
        }
    }
}

/// Maps a route to the screen that draws it. Slices add their screens here.
private struct RouteDestination: View {
    let route: Route
    let userId: String
    let dependencies: KametiDependencies
    let router: AppRouter
    let onFinished: () -> Void
    let knownKameti: (String) -> Kameti?
    let homeModel: HomeViewModel
    let profileModel: ProfileViewModel

    var body: some View {
        switch route {
        case .kametiDetail(let id):
            KametiDetailScreen(kametiId: id, userId: userId, dependencies: dependencies, preview: knownKameti(id), router: router)
        case .kametiAction(let id, let action):
            KametiDetailScreen(kametiId: id, userId: userId, dependencies: dependencies, preview: knownKameti(id), router: router, action: action)
        case .createKameti:
            CreateKametiScreen(userId: userId, dependencies: dependencies, router: router, onFinished: onFinished)
        case .resumeDraft(let id):
            CreateKametiScreen(userId: userId, dependencies: dependencies, router: router, onFinished: onFinished, draftId: id)
        case .join(let token):
            JoinInviteScreen(token: token, inviteId: nil, dependencies: dependencies, router: router, onFinished: onFinished)
        case .invitation(let id):
            JoinInviteScreen(token: nil, inviteId: id, dependencies: dependencies, router: router, onFinished: onFinished)
        case .activity(let id):
            ActivityScreen(kametiId: id, userId: userId, dependencies: dependencies)
        case .archivedKametis:
            ArchivedKametisView(model: homeModel) { router.push(.kametiDetail(id: $0)) }
        case .pastKametis:
            PastKametisView(kametis: profileModel.pastKametis) { router.push(.kametiDetail(id: $0)) }
                .task { await profileModel.load() }
        }
    }
}

/// Owns the activity model for as long as the screen is pushed.
private struct ActivityScreen: View {
    @State private var model: ActivityViewModel

    init(kametiId: String, userId: String, dependencies: KametiDependencies) {
        _model = State(initialValue: ActivityViewModel(kametiId: kametiId, userId: userId, dependencies: dependencies))
    }

    var body: some View { ActivityView(model: model) }
}

/// Owns the accept-invite model. Joining opens the kameti on Home.
private struct JoinInviteScreen: View {
    @State private var model: JoinInviteViewModel
    let router: AppRouter
    let onFinished: () -> Void

    init(token: String?, inviteId: String?, dependencies: KametiDependencies, router: AppRouter, onFinished: @escaping () -> Void) {
        _model = State(initialValue: JoinInviteViewModel(token: token, inviteId: inviteId, dependencies: dependencies))
        self.router = router
        self.onFinished = onFinished
    }

    var body: some View {
        JoinInviteView(
            model: model,
            onJoined: { id in
                onFinished()
                router.inboxPath = []
                router.tab = .home
                router.homePath = [.kametiDetail(id: id)]
            },
            onClose: {
                onFinished()
                router.popToRoot()
            }
        )
    }
}

/// Owns the detail view model, so it lives as long as the screen is pushed.
private struct KametiDetailScreen: View {
    @State private var model: KametiDetailViewModel
    let router: AppRouter

    init(kametiId: String, userId: String, dependencies: KametiDependencies, preview: Kameti?, router: AppRouter, action: RecordAction? = nil) {
        let model = KametiDetailViewModel(kametiId: kametiId, userId: userId, dependencies: dependencies, preview: preview)
        model.pendingAction = action
        _model = State(initialValue: model)
        self.router = router
    }

    var body: some View {
        KametiDetailView(
            model: model,
            onResumeDraft: { router.push(.resumeDraft(id: $0)) },
            onOpenActivity: { router.push(.activity(kametiId: $0)) }
        )
    }
}

/// Owns the wizard model for as long as the wizard is on screen. Closing
/// keeps the draft (it is on the server); starting opens the new kameti.
private struct CreateKametiScreen: View {
    @State private var model: CreateWizardModel
    let router: AppRouter
    let onFinished: () -> Void
    let draftId: String?

    init(userId: String, dependencies: KametiDependencies, router: AppRouter, onFinished: @escaping () -> Void, draftId: String? = nil) {
        _model = State(initialValue: CreateWizardModel(userId: userId, dependencies: dependencies))
        self.router = router
        self.onFinished = onFinished
        self.draftId = draftId
    }

    var body: some View {
        CreateKametiView(
            model: model,
            onStarted: { id in
                onFinished()
                router.homePath = [.kametiDetail(id: id)]
            },
            onClose: {
                onFinished()
                router.popToRoot()
            }
        )
        .task {
            if let draftId, model.kametiId == nil { await model.resume(draftId: draftId) }
        }
    }
}
