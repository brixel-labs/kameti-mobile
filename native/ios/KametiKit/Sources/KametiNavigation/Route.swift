import KametiCore
import Foundation

/// The three tabs of the signed-in app.
public enum AppTab: Hashable, Sendable, CaseIterable {
    case home, inbox, profile
}

/// Every screen a tab's stack can show. Features push these without knowing
/// which feature draws them; FeatureShell maps each route to its view.
public enum Route: Hashable, Sendable {
    case kametiDetail(id: String)
    /// A kameti opened straight into a recording action (Home's Record payment).
    case kametiAction(id: String, action: RecordAction)
    /// The create-kameti wizard.
    case createKameti
    /// The create wizard reopened on a saved draft.
    case resumeDraft(id: String)
    case activity(kametiId: String)
    /// Home's archived kametis (§6.11).
    case archivedKametis
    /// Profile's completed and cancelled kametis.
    case pastKametis
    /// An invite link token or the 6-character code.
    case join(token: String)
    /// An invitation addressed to my email, from Home or Inbox.
    case invitation(id: String)
}
