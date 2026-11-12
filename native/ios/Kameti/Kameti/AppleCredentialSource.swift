import AuthenticationServices
import KametiCore
import KametiData
import UIKit

/// Sign in with Apple: the system sheet, with a nonce Supabase can verify.
struct AppleCredentialSource: ProviderCredentialSource {
    func credential() async throws(Failure) -> ProviderCredential? {
        try await signIn()
    }

    @MainActor
    private func signIn() async throws(Failure) -> ProviderCredential? {
        let nonce = AppleNonce.make()
        let coordinator = AppleSignInCoordinator()
        do {
            let authorization = try await coordinator.authorize(hashedNonce: nonce.hashed)
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8)
            else {
                throw Failure.signIn(.rejected, detail: "Apple returned no identity token")
            }
            return ProviderCredential(idToken: idToken, nonce: nonce.raw)
        } catch let failure as Failure {
            throw failure
        } catch let error as ASAuthorizationError {
            switch error.code {
            case .canceled: return nil
            case .notHandled, .notInteractive: throw .signIn(.unavailable, detail: String(describing: error))
            default: throw .signIn(.rejected, detail: String(describing: error))
            }
        } catch {
            throw .signIn(.rejected, detail: String(describing: error))
        }
    }
}

/// Bridges `ASAuthorizationController`'s delegate callbacks to async/await.
@MainActor
private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private var continuation: CheckedContinuation<ASAuthorization, any Error>?
    private var controller: ASAuthorizationController?

    func authorize(hashedNonce: String) async throws -> ASAuthorization {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = hashedNonce
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller // keep it alive while the sheet is up
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
