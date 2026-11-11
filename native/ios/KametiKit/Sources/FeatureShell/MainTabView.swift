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
                            router.push(homeModel.kameti(id: id)?.status == .draft ? .resumeDraft(id: id) : .kametiDetail(id: id))
                        },
                        onRecord: { router.push(.kametiAction(id: $0, action: $1)) },
                        onCreate: { router.push(.createKameti) },
                        onJoin: { router.push(.join(token: $0)) },
                        onOpenInvitation: { router.push(.invitation(id: $0)) }
                    )
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0, userId: userId, dependencies: dependencies, router: router, onFinished: { Task { await homeModel.load() } }, knownKameti: { homeModel.kameti(id: $0) }) }
                }
            } label: {
                Label(String(localized: "Home", bundle: .module), systemImage: "house")
            }

            Tab(value: AppTab.inbox) {
                NavigationStack(path: $router.inboxPath) {
                    InboxView(model: inboxModel) { router.push(.invitation(id: $0)) }
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0, userId: userId, dependencies: dependencies, router: router, onFinished: { Task { await homeModel.load() } }, knownKameti: { homeModel.kameti(id: $0) }) }
                }
            } label: {
                Label(String(localized: "Inbox", bundle: .module), systemImage: "tray")
            }
            .badge(inboxModel.invitations.count + inboxModel.requests.count)

            Tab(value: AppTab.profile) {
                NavigationStack(path: $router.profilePath) {
                    ProfileView(model: profileModel)
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0, userId: userId, dependencies: dependencies, router: router, onFinished: { Task { await homeModel.load() } }, knownKameti: { homeModel.kameti(id: $0) }) }
                }
            } label: {
                Label(String(localized: "Profile", bundle: .module), systemImage: "person")
            }
        }
        .tint(KColors.brand)
        // Keeps the Inbox badge current from the first launch.
        .task { await inboxModel.load() }
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
