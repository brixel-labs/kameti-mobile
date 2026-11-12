import Foundation
import Functions
import KametiCore
import PostgREST
import Auth

extension Failure {
    /// Turns anything the Supabase SDK or URLSession throws into a `Failure`
    /// (REQUIREMENTS: repositories never leak raw errors into the UI).
    init(mapping error: any Error) {
        switch error {
        case let failure as Failure:
            self = failure
        case let error as PostgrestError:
            // Kameti RPCs raise `message = <stable key>, details = <english text>`.
            self = .server(code: error.message, detail: error.details)
        case let error as AuthError:
            self = .auth(message: error.message)
        case let error as FunctionsError:
            switch error {
            case .relayError: self = .network
            case .httpError(let code, _): self = .server(code: "function_http_\(code)", detail: nil)
            }
        case let error as URLError:
            switch error.code {
            case .notConnectedToInternet, .timedOut, .networkConnectionLost,
                 .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
                 .internationalRoamingOff, .dataNotAllowed:
                self = .network
            default:
                self = .unknown(description: error.localizedDescription)
            }
        case is CancellationError:
            self = .unknown(description: "cancelled")
        default:
            self = .unknown(description: String(describing: error))
        }
    }
}

/// Runs `body` and rethrows anything it throws as a `Failure`.
func run<T>(_ body: () async throws -> T) async throws(Failure) -> T {
    do {
        return try await body()
    } catch {
        throw Failure(mapping: error)
    }
}
