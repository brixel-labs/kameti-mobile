import Foundation
import Observation

/// Navigation state for the signed-in app: the selected tab and one
/// navigation stack per tab. Plain state, so tests drive it directly and the
/// views just bind to it.
@MainActor
@Observable
public final class AppRouter {
    public var tab: AppTab = .home
    public var homePath: [Route] = []
    public var inboxPath: [Route] = []
    public var profilePath: [Route] = []

    public init() {}

    /// Pushes onto the current tab's stack.
    public func push(_ route: Route) {
        switch tab {
        case .home: homePath.append(route)
        case .inbox: inboxPath.append(route)
        case .profile: profilePath.append(route)
        }
    }

    /// Pops the current tab's stack back to its first screen.
    public func popToRoot() {
        switch tab {
        case .home: homePath.removeAll()
        case .inbox: inboxPath.removeAll()
        case .profile: profilePath.removeAll()
        }
    }

    /// Opens a link (an invite, say) on the Home tab. Returns whether the URL
    /// was one we handle.
    @discardableResult
    public func open(_ url: URL) -> Bool {
        guard let route = DeepLink.route(for: url) else { return false }
        tab = .home
        homePath = [route]
        return true
    }
}
