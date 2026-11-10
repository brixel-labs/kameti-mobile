import Foundation

/// The three tabs of the signed-in app.
public enum AppTab: Hashable, Sendable, CaseIterable {
    case home, inbox, profile
}

/// Every screen a tab's stack can show. Features push these without knowing
/// which feature draws them; FeatureShell maps each route to its view.
public enum Route: Hashable, Sendable {
    case kametiDetail(id: String)
    case activity(kametiId: String)
    /// An invite link token or the 6-character code.
    case join(token: String)
}
