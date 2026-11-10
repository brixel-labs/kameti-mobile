import GoogleSignIn
import KametiCore
import KametiData
import UIKit

/// Google's account picker, then the ID and access tokens for Supabase.
struct GoogleCredentialSource: ProviderCredentialSource {
    let clientID: String
    let serverClientID: String

    func credential() async throws(Failure) -> ProviderCredential? {
        try await signIn()
    }

    @MainActor
    private func signIn() async throws(Failure) -> ProviderCredential? {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID, serverClientID: serverClientID
        )
        guard let presenter = UIApplication.topViewController else {
            throw .signIn(.unavailable, detail: "no view controller to present Google sign-in from")
        }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                throw Failure.signIn(.rejected, detail: "Google returned no ID token")
            }
            return ProviderCredential(idToken: idToken, accessToken: result.user.accessToken.tokenString)
        } catch let failure as Failure {
            throw failure
        } catch let error as GIDSignInError {
            if error.code == .canceled { return nil }
            throw .signIn(.rejected, detail: String(describing: error))
        } catch {
            throw .signIn(.rejected, detail: String(describing: error))
        }
    }
}

extension UIApplication {
    /// The view controller on top of the key window, to present sheets from.
    @MainActor static var topViewController: UIViewController? {
        let scene = shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
