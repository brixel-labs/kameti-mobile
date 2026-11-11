import SwiftUI
import UIKit

/// The owner's choice of light, dark or following the system. Stored with
/// `@AppStorage(KAppearance.storageKey)` and applied once at the root.
public enum KAppearance: String, CaseIterable, Sendable {
    case system, light, dark

    public static let storageKey = "kameti.appearance"

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// Applies the choice to every window of the app, so screens and sheets
    /// that are already open (the Appearance sheet itself) switch together,
    /// and System really follows the phone again.
    @MainActor public func applyToWindows() {
        let style: UIUserInterfaceStyle = switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
        for scene in UIApplication.shared.connectedScenes {
            for window in (scene as? UIWindowScene)?.windows ?? [] {
                window.overrideUserInterfaceStyle = style
            }
        }
    }

    public var title: String {
        switch self {
        case .system: String(localized: "System", bundle: .module)
        case .light: String(localized: "Light", bundle: .module)
        case .dark: String(localized: "Dark", bundle: .module)
        }
    }
}
