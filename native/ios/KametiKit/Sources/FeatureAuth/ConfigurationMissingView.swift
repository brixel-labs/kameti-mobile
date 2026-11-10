import KametiUI
import SwiftUI

/// Shown when the app has no backend settings (no `KametiConfig.json`), so it
/// says why sign-in is off instead of pretending.
public struct ConfigurationMissingView: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: KSpace.md) {
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 40))
                .foregroundStyle(KColors.warning)
                .accessibilityHidden(true)
            Text("This build isn't connected to the Kameti service, so sign-in is turned off.", bundle: .module)
                .kText(KTextToken.title)
            #if DEBUG
            Text("Developers: run native/ios/scripts/use-env.sh dev (or prod), then build again.", bundle: .module)
                .kText(KTextToken.subtitle, color: KColors.textSubtitle)
            #endif
        }
        .padding(KSpace.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(KColors.background)
    }
}
