import KametiCore
import SwiftUI

/// What a confirm sheet shows after its action ran.
public enum KConfirmOutcome: Sendable {
    /// Close the sheet.
    case dismiss
    /// Stay open and show a result with a Done button.
    case result(KSheetMessage)
}

/// A title and message for a result or a notice sheet.
public struct KSheetMessage: Sendable, Equatable {
    public enum Tone: Sendable { case success, info, warning, error }
    public let title: String
    public let message: String
    public let tone: Tone

    public init(_ title: String, message: String, tone: Tone = .info) {
        self.title = title; self.message = message; self.tone = tone
    }

    var symbol: String {
        switch tone {
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch tone {
        case .success: KColors.positive
        case .info: KColors.brand
        case .warning: KColors.warning
        case .error: KColors.negative
        }
    }
}

public extension View {
    /// A confirmation as a bottom sheet (the app's replacement for alerts):
    /// a message, optional details such as a list of people, then Cancel and
    /// the primary action. The primary button spins while `onConfirm` runs;
    /// it can then close the sheet or show a result in place.
    func kConfirmSheet<Details: View>(
        isPresented: Binding<Bool>, title: String, message: String? = nil,
        confirmTitle: String, isDestructive: Bool = false,
        @ViewBuilder details: @escaping () -> Details,
        onConfirm: @escaping () async -> KConfirmOutcome
    ) -> some View {
        modifier(KConfirmSheetModifier(
            isPresented: isPresented, title: title, message: message, confirmTitle: confirmTitle,
            isDestructive: isDestructive, details: details, onConfirm: onConfirm
        ))
    }

    /// The same, for an alert that was presented for an item.
    func kConfirmSheet<Item: Sendable, Details: View>(
        item: Binding<Item?>, title: @escaping (Item) -> String, message: @escaping (Item) -> String?,
        confirmTitle: String, isDestructive: Bool = false,
        @ViewBuilder details: @escaping (Item) -> Details,
        onConfirm: @escaping (Item) async -> KConfirmOutcome
    ) -> some View {
        // Keep the item while the sheet animates away, so the text doesn't blank.
        modifier(KItemConfirmSheetModifier(
            item: item, title: title, message: message, confirmTitle: confirmTitle,
            isDestructive: isDestructive, details: details, onConfirm: onConfirm
        ))
    }

    /// A confirmation with no details below the message.
    func kConfirmSheet(
        isPresented: Binding<Bool>, title: String, message: String? = nil,
        confirmTitle: String, isDestructive: Bool = false,
        onConfirm: @escaping () async -> KConfirmOutcome
    ) -> some View {
        kConfirmSheet(
            isPresented: isPresented, title: title, message: message, confirmTitle: confirmTitle,
            isDestructive: isDestructive, details: { EmptyView() }, onConfirm: onConfirm
        )
    }

    /// An item confirmation with no details below the message.
    func kConfirmSheet<Item: Sendable>(
        item: Binding<Item?>, title: @escaping (Item) -> String, message: @escaping (Item) -> String?,
        confirmTitle: String, isDestructive: Bool = false,
        onConfirm: @escaping (Item) async -> KConfirmOutcome
    ) -> some View {
        kConfirmSheet(
            item: item, title: title, message: message, confirmTitle: confirmTitle,
            isDestructive: isDestructive, details: { _ in EmptyView() }, onConfirm: onConfirm
        )
    }

    /// A notice (an error or a result) as a bottom sheet with one OK button.
    func kMessageSheet(_ message: Binding<KSheetMessage?>) -> some View {
        modifier(KMessageSheetModifier(message: message))
    }

    /// An error notice for a failed action, as a bottom sheet.
    func kFailureSheet(_ failure: Binding<Failure?>, title: String, message: @escaping (Failure) -> String = { $0.userMessage }) -> some View {
        kMessageSheet(Binding(
            get: { failure.wrappedValue.map { KSheetMessage(title, message: message($0), tone: .error) } },
            set: { if $0 == nil { failure.wrappedValue = nil } }
        ))
    }
}

// MARK: - Modifiers

private struct KConfirmSheetModifier<Details: View>: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let confirmTitle: String
    let isDestructive: Bool
    let details: () -> Details
    let onConfirm: () async -> KConfirmOutcome
    @State private var height: CGFloat = 220
    @State private var isWorking = false

    func body(content: Content) -> some View {
        content.kBottomSheet(
            isPresented: $isPresented, title: title, detents: [.height(height + KSheetMetrics.titleRow)], dismissDisabled: isWorking
        ) {
            KConfirmBody(
                message: message, confirmTitle: confirmTitle, isDestructive: isDestructive,
                details: details, onConfirm: onConfirm, close: { isPresented = false }, isWorking: $isWorking
            )
            // While working, the sheet keeps its height (rows leaving don't make it jump).
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = isWorking ? max(height, $0) : $0 }
        }
    }
}

private struct KItemConfirmSheetModifier<Item: Sendable, Details: View>: ViewModifier {
    @Binding var item: Item?
    let title: (Item) -> String
    let message: (Item) -> String?
    let confirmTitle: String
    let isDestructive: Bool
    let details: (Item) -> Details
    let onConfirm: (Item) async -> KConfirmOutcome
    @State private var shown: Item?
    @State private var height: CGFloat = 220
    @State private var isWorking = false

    func body(content: Content) -> some View {
        content
            .onChange(of: item != nil, initial: true) { _, isSet in if isSet { shown = item } }
            .kBottomSheet(
                isPresented: Binding(get: { item != nil }, set: { if !$0 { item = nil } }),
                title: shown.map(title) ?? "", detents: [.height(height + KSheetMetrics.titleRow)], dismissDisabled: isWorking
            ) {
                if let shown {
                    KConfirmBody(
                        message: message(shown), confirmTitle: confirmTitle, isDestructive: isDestructive,
                        details: { details(shown) }, onConfirm: { await onConfirm(shown) }, close: { item = nil },
                        isWorking: $isWorking
                    )
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = isWorking ? max(height, $0) : $0 }
                }
            }
    }
}

private struct KMessageSheetModifier: ViewModifier {
    @Binding var message: KSheetMessage?
    @State private var shown: KSheetMessage?
    @State private var height: CGFloat = 200

    func body(content: Content) -> some View {
        content
            .onChange(of: message, initial: true) { _, new in if let new { shown = new } }
            .kBottomSheet(
                isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } }),
                title: "", detents: [.height(height + KSheetMetrics.titleRow)]
            ) {
                if let shown {
                    KResultBody(result: shown, buttonTitle: String(localized: "OK", bundle: .module)) { message = nil }
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
                }
            }
    }
}

enum KSheetMetrics {
    /// The shared sheet's title row: 24 above, the title, 12 below.
    static let titleRow: CGFloat = 58
}

// MARK: - Bodies

private struct KConfirmBody<Details: View>: View {
    let message: String?
    let confirmTitle: String
    let isDestructive: Bool
    let details: () -> Details
    let onConfirm: () async -> KConfirmOutcome
    let close: () -> Void
    @Binding var isWorking: Bool
    @State private var result: KSheetMessage?

    var body: some View {
        Group {
            if let result {
                KResultBody(result: result, buttonTitle: String(localized: "Done", bundle: .module), action: close)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    if let message {
                        Text(message).kText(KTextToken.body, color: KColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    details()
                    HStack(spacing: KSpace.md) {
                        Button(action: close) {
                            Text("Cancel", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textPrimary)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)
                        .disabled(isWorking)
                        Button(action: confirm) {
                            ZStack {
                                Text(confirmTitle).opacity(isWorking ? 0 : 1)
                                if isWorking { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                            }
                            .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(isDestructive ? KColors.negative : KColors.brand)
                        .controlSize(.large)
                        .allowsHitTesting(!isWorking)
                    }
                }
                .padding(.horizontal, KSpace.xl)
                .padding(.bottom, KSpace.lg)
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.3), value: result)
    }

    private func confirm() {
        isWorking = true
        Task {
            let outcome = await onConfirm()
            isWorking = false
            switch outcome {
            case .dismiss: close()
            case .result(let message): result = message
            }
        }
    }
}

/// An icon, a title and a message, then one button.
struct KResultBody: View {
    let result: KSheetMessage
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: KSpace.md) {
            Image(systemName: result.symbol)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(result.tint)
                .symbolEffect(.bounce, value: result)
            Text(result.title).kText(KTextToken.title).multilineTextAlignment(.center)
            Text(result.message).kText(KTextToken.body, color: KColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: action) {
                Text(buttonTitle).kText(KTextToken.bodyStrong, color: KColors.textOnBrand).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            .padding(.top, KSpace.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, KSpace.xl)
        .padding(.bottom, KSpace.lg)
    }
}
