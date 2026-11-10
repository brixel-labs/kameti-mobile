import SwiftUI

/// Google's multicolour "G" for the Continue with Google button. It is
/// Google's brand artwork, so its colours are not themed.
public struct KGoogleLogo: View {
    public init() {}

    public var body: some View {
        Image("GoogleG", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
    }
}
