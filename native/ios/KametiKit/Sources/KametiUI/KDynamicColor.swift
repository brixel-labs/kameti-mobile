import SwiftUI
import UIKit

/// A colour with a light and a dark value that follows the system appearance.
public struct KDynamicColor: Sendable {
    public let light: UInt32
    public let lightAlpha: Double
    public let dark: UInt32
    public let darkAlpha: Double

    public init(light: UInt32, lightAlpha: Double = 1, dark: UInt32, darkAlpha: Double = 1) {
        self.light = light; self.lightAlpha = lightAlpha
        self.dark = dark; self.darkAlpha = darkAlpha
    }

    public var color: Color {
        let light = self.light, lightAlpha = self.lightAlpha
        let dark = self.dark, darkAlpha = self.darkAlpha
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension KColors {
    /// The palette entry for a member's colour index (wraps around).
    public static func avatar(_ index: Int) -> (background: Color, foreground: Color) {
        avatars[((index % avatars.count) + avatars.count) % avatars.count]
    }
}
