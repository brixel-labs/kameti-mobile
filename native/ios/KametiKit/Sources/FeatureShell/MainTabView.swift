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

    init(router: AppRouter, userId: String, dependencies: KametiDependencies) {
        self.router = router
        self.userId = userId
        self.dependencies = dependencies
        _profileModel = State(initialValue: ProfileViewModel(userId: userId, dependencies: dependencies))
    }

    var body: some View {
        TabView(selection: $router.tab) {
            Tab(value: AppTab.home) {
                NavigationStack(path: $router.homePath) {
                    ComingNextView(title: String(localized: "Home", bundle: .module), symbol: "house",
                                   message: String(localized: "Your kametis are coming next.", bundle: .module))
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
                }
            } label: {
                Label(String(localized: "Home", bundle: .module), systemImage: "house")
            }

            Tab(value: AppTab.inbox) {
                NavigationStack(path: $router.inboxPath) {
                    ComingNextView(title: String(localized: "Inbox", bundle: .module), symbol: "tray",
                                   message: String(localized: "Invitations and join requests will show here.", bundle: .module))
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
                }
            } label: {
                Label(String(localized: "Inbox", bundle: .module), systemImage: "tray")
            }

            Tab(value: AppTab.profile) {
                NavigationStack(path: $router.profilePath) {
                    ProfileView(model: profileModel)
                        .navigationDestination(for: Route.self) { RouteDestination(route: $0) }
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

    var body: some View {
        ContentUnavailableView(
            String(localized: "Kameti detail is coming next.", bundle: .module),
            systemImage: "hammer"
        )
    }
}
