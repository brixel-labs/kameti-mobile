import FeatureCreateKameti
import FeatureHome
import FeatureKametiDetail
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

    init(router: AppRouter, userId: String, dependencies: KametiDependencies) {
        self.router = router
        self.userId = userId
        self.dependencies = dependencies
        _profileModel = State(initialValue: ProfileViewModel(userId: userId, dependencies: dependencies))
        _homeModel = State(initialValue: HomeViewModel(userId: userId, dependencies: dependencies))
    }

    var body: some View {
        TabView(selection: $router.tab) {
            Tab(value: AppTab.home) {
                NavigationStack(path: $router.homePath) {
                    HomeView(
                        model: homeModel,
                        onOpen: { router.push(.kametiDetail(id: $0)) },
                        onCreate: { router.push(.createKameti) },
                        onJoin: { router.push(.join(token: $0)) }
                    )
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0, userId: userId, dependencies: dependencies, router: router, onFinished: { Task { await homeModel.load() } }, knownKameti: { homeModel.kameti(id: $0) }) }
                }
            } label: {
                Label(String(localized: "Home", bundle: .module), systemImage: "house")
            }

            Tab(value: AppTab.inbox) {
                NavigationStack(path: $router.inboxPath) {
                    ComingNextView(title: String(localized: "Inbox", bundle: .module), symbol: "tray",
                                   message: String(localized: "Invitations and join requests will show here.", bundle: .module))
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0, userId: userId, dependencies: dependencies, router: router, onFinished: { Task { await homeModel.load() } }, knownKameti: { homeModel.kameti(id: $0) }) }
                }
            } label: {
                Label(String(localized: "Inbox", bundle: .module), systemImage: "tray")
            }

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
    }
}

/// A tab whose screen lands in a later slice.
private struct ComingNextView: View {
    let title: String
    let symbol: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(message))
            .background(KColors.background)
            .navigationTitle(title)
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
            KametiDetailScreen(kametiId: id, userId: userId, dependencies: dependencies, preview: knownKameti(id))
        case .createKameti:
            CreateKametiScreen(userId: userId, dependencies: dependencies, router: router, onFinished: onFinished)
        case .activity, .join:
            ContentUnavailableView(
                String(localized: "This screen is coming next.", bundle: .module),
                systemImage: "hammer"
            )
        }
    }
}

/// Owns the detail view model, so it lives as long as the screen is pushed.
private struct KametiDetailScreen: View {
    @State private var model: KametiDetailViewModel

    init(kametiId: String, userId: String, dependencies: KametiDependencies, preview: Kameti?) {
        _model = State(initialValue: KametiDetailViewModel(kametiId: kametiId, userId: userId, dependencies: dependencies, preview: preview))
    }

    var body: some View { KametiDetailView(model: model) }
}

/// Owns the wizard model for as long as the wizard is on screen. Closing
/// keeps the draft (it is on the server); starting opens the new kameti.
private struct CreateKametiScreen: View {
    @State private var model: CreateWizardModel
    let router: AppRouter
    let onFinished: () -> Void

    init(userId: String, dependencies: KametiDependencies, router: AppRouter, onFinished: @escaping () -> Void) {
        _model = State(initialValue: CreateWizardModel(userId: userId, dependencies: dependencies))
        self.router = router
        self.onFinished = onFinished
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
    }
}
