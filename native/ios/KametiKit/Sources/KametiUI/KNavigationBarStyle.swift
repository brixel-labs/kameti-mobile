import SwiftUI
import UIKit

/// Styles the system navigation bar's subtitle (the line under a title) to
/// match the app's readable subtitle colour. The system title and subtitle show
/// instantly while a screen is being pushed, unlike a custom title view.
public enum KNavigationBarStyle {
    @MainActor public static func apply() {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(KColors.textSubtitle),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
        ]
        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        standard.subtitleTextAttributes = attributes
        let edge = UINavigationBarAppearance()
        edge.configureWithTransparentBackground()
        edge.subtitleTextAttributes = attributes
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = standard
        bar.scrollEdgeAppearance = edge
    }
}
