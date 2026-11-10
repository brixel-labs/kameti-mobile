/// Why a sign-in with Apple or Google didn't complete. (A cancelled sheet is
/// not a failure; sign-in returns `false` for it.)
public enum SignInProblem: Sendable, Equatable {
    /// This build has no backend settings.
    case notConfigured
    /// The provider's client IDs or signing key don't match this build.
    case misconfigured
    /// The sign-in sheet was interrupted before it finished.
    case interrupted
    /// Sign-in can't be shown right now (no account on the device, no UI).
    case unavailable
    /// The provider answered but Kameti's backend refused the sign-in.
    case rejected
}

/// Why a call failed. Repositories throw this (typed throws), never a raw
/// Supabase or URLSession error, so screens can turn it into a message.
public enum Failure: Error, Sendable, Equatable {
    /// A rule the backend enforced, for example `shares_must_sum_to_slot_amount`,
    /// `not_kameti_owner` or `future_date`. `detail` is the English text the
    /// backend sent; it is for logs, not for users.
    case server(code: String, detail: String?)
    /// No connection, or the request timed out.
    case network
    /// Sign-in problem or the session expired.
    case auth(message: String)
    /// A sign-in that failed, with a reason the screen can explain.
    case signIn(SignInProblem, detail: String?)
    case unknown(description: String)
}
