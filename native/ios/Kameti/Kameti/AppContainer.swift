import FeatureAuth
import FeatureShell
import KametiData
import KametiDomain
import KametiNavigation

/// The composition root: the one place that turns the config into the real
/// (Supabase) dependencies and hands them to the features.
@MainActor
struct AppContainer {
    let session: SessionStore
    let router: AppRouter
    let signIn: SignInViewModel
    let dependencies: KametiDependencies

    init(config: AppConfig) {
        let google = config.googleIOSClientID.flatMap { iosID in
            config.googleWebClientID.map { GoogleCredentialSource(clientID: iosID, serverClientID: $0) }
        }
        dependencies = KametiBackend.makeDependencies(
            url: config.supabaseURL,
            publishableKey: config.supabasePublishableKey,
            google: google,
            apple: AppleCredentialSource()
        )
        session = SessionStore(auth: dependencies.auth)
        router = AppRouter()
        signIn = SignInViewModel(auth: dependencies.auth, showsDevSignIn: config.isDev)
    }
}
