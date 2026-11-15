import SwiftUI

/// Icons with no SF Symbol, drawn as outlines in the asset catalog so iOS and Android show the same shapes.
/// Use them like a symbol: they take the surrounding foreground colour.
public enum KIcon {
    /// A broken link: turn a link off.
    public static func linkOff(size: CGFloat = 22) -> some View { icon("kLinkOff", size: size) }
    /// A person with a plus: invite.
    public static func userPlus(size: CGFloat = 22) -> some View { icon("kUserPlus", size: size) }

    private static func icon(_ name: String, size: CGFloat) -> some View {
        Image(name, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
