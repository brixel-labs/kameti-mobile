import FeatureAuth
import KametiDomain
import KametiNavigation
import KametiUI
import SwiftUI

/// The root of the app: signed out shows sign-in, signed in shows the tabs.
public struct RootView: View {
    private let session: SessionStore
    private let router: AppRouter
    private let signIn: SignInViewModel
    private let dependencies: KametiDependencies
    @AppStorage(KAppearance.storageKey) private var appearance = KAppearance.system.rawValue

    public init(
        session: SessionStore, router: AppRouter, signIn: SignInViewModel,
        dependencies: KametiDependencies
    ) {
        self.session = session
        self.router = router
        self.signIn = signIn
        self.dependencies = dependencies
    }

    public var body: some View {
        Group {
            switch session.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(KColors.background)
            case .signedOut:
                SignInView(model: signIn)
            case .signedIn(let userId):
                MainTabView(router: router, userId: userId, dependencies: dependencies)
                    // A new user gets a fresh view model and a clean tab state.
                    .id(userId)
            }
        }
        // On the windows, not `preferredColorScheme`: that misses sheets
        // already on screen and doesn't always return to System.
        .onAppear { (KAppearance(rawValue: appearance) ?? .system).applyToWindows() }
        .onChange(of: appearance) { _, new in (KAppearance(rawValue: new) ?? .system).applyToWindows() }
        .animation(.default, value: session.state)
        .task { session.start() }
        .onOpenURL { router.open($0) }
    }
}
