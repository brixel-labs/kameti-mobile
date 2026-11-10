import SwiftUI

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

    public var title: String {
        switch self {
        case .system: String(localized: "System", bundle: .module)
        case .light: String(localized: "Light", bundle: .module)
        case .dark: String(localized: "Dark", bundle: .module)
        }
    }
}
