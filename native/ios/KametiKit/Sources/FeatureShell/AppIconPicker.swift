import KametiUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The home-screen icons the app ships (asset catalog: `AppIcon` and its
/// alternates). Previews are separate image sets in the app bundle, because
/// an app icon set can't be loaded as an image.
enum KAppIcon: String, CaseIterable, Identifiable {
    case circle, midnight, monogram, turns

    var id: String { rawValue }

    /// The alternate icon's name; `nil` is the main icon.
    var alternateName: String? {
        switch self {
        case .circle: nil
        case .midnight: "AppIcon-Midnight"
        case .monogram: "AppIcon-Monogram"
        case .turns: "AppIcon-Turns"
        }
    }

    var previewName: String {
        switch self {
        case .circle: "IconPreview-Circle"
        case .midnight: "IconPreview-Midnight"
        case .monogram: "IconPreview-Monogram"
        case .turns: "IconPreview-Turns"
        }
    }

    var detail: String {
        switch self {
        case .circle: String(localized: "The default", bundle: .module)
        case .midnight: String(localized: "Deep green, glowing mint", bundle: .module)
        case .monogram: String(localized: "Just the letter", bundle: .module)
        case .turns: String(localized: "The pot, one turn lit", bundle: .module)
        }
    }

    var title: String {
        switch self {
        case .circle: String(localized: "Circle", bundle: .module)
        case .midnight: String(localized: "Midnight", bundle: .module)
        case .monogram: String(localized: "K", bundle: .module)
        case .turns: String(localized: "Turns", bundle: .module)
        }
    }

    @MainActor static var isSupported: Bool {
        #if canImport(UIKit)
        UIApplication.shared.supportsAlternateIcons
        #else
        false
        #endif
    }

    @MainActor static var current: KAppIcon {
        #if canImport(UIKit)
        let name = UIApplication.shared.alternateIconName
        return allCases.first { $0.alternateName == name } ?? .circle
        #else
        return .circle
        #endif
    }
}

/// The icons as a list (board: App icon sheet A): preview, name and a short
/// description, a ticked circle on the chosen one. Tapping a row changes the
/// home-screen icon; iOS confirms with its own alert (it can't be turned off).
struct AppIconPicker: View {
    @Binding var selection: KAppIcon
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            ForEach(KAppIcon.allCases) { icon in row(icon) }
            message
                .padding(.top, KSpace.xs)
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.top, KSpace.xs)
        .padding(.bottom, KSpace.xl)
        .animation(.smooth(duration: 0.25), value: failed)
    }

    @ViewBuilder private var message: some View {
        if failed {
            Label {
                Text("The icon couldn't be changed. Try again.", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.negative)
            } icon: {
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(KColors.negative)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(KSpace.md)
            .background(KColors.negativeSubtle, in: RoundedRectangle(cornerRadius: KRadius.input))
            .transition(.opacity)
        } else {
            Text("Changes the icon on your Home Screen. Only on this phone.", bundle: .module)
                .kText(KTextToken.bodySm, color: KColors.textSecondary)
        }
    }

    private func row(_ icon: KAppIcon) -> some View {
        let isOn = selection == icon
        return Button { choose(icon) } label: {
            HStack(spacing: KSpace.md) {
                Image(icon.previewName, bundle: .main)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(KColors.border, lineWidth: 0.5))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(icon.title).kText(KTextToken.bodyStrong)
                    Text(icon.detail).kText(KTextToken.bodySm, color: KColors.textSecondary)
                }
                Spacer(minLength: KSpace.sm)
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isOn ? KColors.brand : KColors.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, KSpace.md)
            .padding(.vertical, KSpace.sm + 2)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: KRadius.card)
                    .strokeBorder(isOn ? KColors.brand : KColors.border, lineWidth: isOn ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func choose(_ icon: KAppIcon) {
        guard icon != selection else { return }
        let previous = selection
        withAnimation(.smooth(duration: 0.25)) { selection = icon; failed = false }
        #if canImport(UIKit)
        Task {
            do {
                // iOS always confirms an icon change with its own alert; this
                // returns once that alert is closed.
                try await UIApplication.shared.setAlternateIconName(icon.alternateName)
            } catch {
                withAnimation(.smooth(duration: 0.25)) { selection = previous }
                failed = true
            }
        }
        #endif
    }
}
