import FeatureAuth
import FeatureShell
import GoogleSignIn
import SwiftUI

@main
struct KametiApp: App {
    @State private var container = AppConfig.load().map { AppContainer(config: $0) }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView(
                    session: container.session, router: container.router,
                    signIn: container.signIn, dependencies: container.dependencies
                )
                .onOpenURL { _ = GIDSignIn.sharedInstance.handle($0) }
            } else {
                ConfigurationMissingView()
            }
        }
    }
}
