import KametiCore
import SwiftUI
import UIKit

public extension KSize {
    /// One height for every single-line control (field, stepper, select).
    static let fieldHeight: CGFloat = 56
}

// Shared input controls: amount field, chips, stepper, bottom sheet and a
// sheet-based select. Every feature uses these, never SwiftUI's raw controls.

/// Hides the keyboard.
@MainActor public func kDismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

public extension View {
    /// Tapping empty space or dragging a scroll view down hides the keyboard,
    /// and number pads (which have no return key) get a Done button.
    func kDismissesKeyboard() -> some View {
        scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(TapGesture().onEnded { kDismissKeyboard() })
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done", bundle: .module)) { kDismissKeyboard() }
                }
            }
    }
}

/// A rupee amount field. `digits` holds only the digits; the field shows them
/// in lakh/crore grouping as you type (`2,50,000`).
public struct KAmountField: View {
    private let title: String
    @Binding private var digits: String
    private let error: String?
    private let helper: String?

    public init(_ title: String, digits: Binding<String>, error: String? = nil, helper: String? = nil) {
        self.title = title; _digits = digits; self.error = error; self.helper = helper
    }

    /// `250000` becomes `2,50,000`; empty stays empty.
    public nonisolated static func grouped(_ digits: String) -> String {
        guard let value = Int(digits) else { return "" }
        return Money(value).format(symbol: false)
    }

    private var text: Binding<String> {
        Binding(
            get: { Self.grouped(digits) },
            set: { digits = String($0.filter(\.isNumber).drop { $0 == "0" }.prefix(10)) }
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: KSpace.xs) {
            Text(title).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            HStack(spacing: KSpace.sm) {
                Text("Rs").kText(KTextToken.body, color: KColors.textSecondary)
                TextField("0", text: text)
                    .keyboardType(.numberPad)
                    .kText(KTextToken.title)
            }
            .padding(.horizontal, KSpace.md)
            .frame(minHeight: KSize.fieldHeight)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
            .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(error == nil ? KColors.border : KColors.negative))
            if let error {
                Text(error).kText(KTextToken.caption, color: KColors.negative)
            } else if let helper {
                Text(helper).kText(KTextToken.caption, color: KColors.textSecondary)
            }
        }
    }
}

/// Just the grouped number input (no title, no frame), for rows with an amount.
public struct KAmountInput: View {
    @Binding private var digits: String
    private let prompt: String

    public init(digits: Binding<String>, prompt: String = "0") {
        _digits = digits; self.prompt = prompt
    }

    public var body: some View {
        TextField(prompt, text: Binding(
            get: { KAmountField.grouped(digits) },
            set: { digits = String($0.filter(\.isNumber).drop { $0 == "0" }.prefix(10)) }
        ))
        .keyboardType(.numberPad)
    }
}

/// A pill that can be selected: filled brand colour when on.
public struct KChip: View {
    private let title: String
    private let isOn: Bool
    private let action: () -> Void

    public init(_ title: String, isOn: Bool, action: @escaping () -> Void) {
        self.title = title; self.isOn = isOn; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .kText(KTextToken.bodyStrong, color: isOn ? KColors.textOnBrand : KColors.textPrimary)
                .padding(.horizontal, KSpace.md)
                .padding(.vertical, KSpace.sm)
                .background(isOn ? KColors.brand : KColors.surface, in: Capsule())
                .overlay(Capsule().stroke(isOn ? KColors.brand : KColors.border))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Wraps its children onto as many lines as needed.
public struct KFlowLayout: Layout {
    private let spacing: CGFloat

    public init(spacing: CGFloat = KSpace.sm) { self.spacing = spacing }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}

/// A − value + control with round buttons.
public struct KStepper: View {
    private let value: Int
    private let range: ClosedRange<Int>
    private let decreaseLabel: String
    private let increaseLabel: String
    private let onChange: (Int) -> Void

    public init(
        value: Int, range: ClosedRange<Int>, decreaseLabel: String, increaseLabel: String,
        onChange: @escaping (Int) -> Void
    ) {
        self.value = value; self.range = range
        self.decreaseLabel = decreaseLabel; self.increaseLabel = increaseLabel; self.onChange = onChange
    }

    public var body: some View {
        HStack {
            roundButton("minus", label: decreaseLabel, enabled: value > range.lowerBound) { onChange(value - 1) }
            Spacer()
            Text("\(value)").kText(KTextToken.title).monospacedDigit()
            Spacer()
            roundButton("plus", label: increaseLabel, enabled: value < range.upperBound) { onChange(value + 1) }
        }
        .padding(.horizontal, KSpace.sm)
        .frame(height: KSize.fieldHeight)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
        .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(KColors.border))
        .accessibilityElement(children: .contain)
    }

    private func roundButton(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(enabled ? KColors.onBrandSubtle : KColors.textTertiary)
                .frame(width: 36, height: 36)
                .background(enabled ? KColors.brandSubtle : KColors.surfaceSunken, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

public extension View {
    /// The shared bottom sheet: grabber, a title with a close button and the content.
    func kBottomSheet<Content: View>(
        isPresented: Binding<Bool>, title: String,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented) {
            VStack(spacing: 0) {
                HStack {
                    Text(title).kText(KTextToken.title)
                    Spacer()
                    Button { isPresented.wrappedValue = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(KColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(KColors.surfaceSunken, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Close", bundle: .module))
                }
                .padding(.horizontal, KSpace.xl)
                .padding(.top, KSpace.xl)
                .padding(.bottom, KSpace.md)
                content()
            }
            .background(KColors.background)
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackground(KColors.background)
        }
    }
}

/// A field that opens a bottom sheet of options (a month, a day, ...).
public struct KSelectField<Value: Hashable>: View {
    private let title: String
    private let sheetTitle: String
    private let options: [(value: Value, label: String)]
    @Binding private var selection: Value
    @State private var isOpen = false

    public init(_ title: String, sheetTitle: String? = nil, selection: Binding<Value>, options: [(value: Value, label: String)]) {
        self.title = title; self.sheetTitle = sheetTitle ?? title
        _selection = selection; self.options = options
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: KSpace.xs) {
            Text(title).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            Button { kDismissKeyboard(); isOpen = true } label: {
                HStack {
                    Text(options.first { $0.value == selection }?.label ?? "").kText(KTextToken.body)
                    Spacer(minLength: KSpace.xs)
                    Image(systemName: "chevron.down").imageScale(.small).foregroundStyle(KColors.textSecondary)
                }
                .padding(.horizontal, KSpace.md)
                .frame(height: KSize.fieldHeight)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(KColors.border))
            }
            .buttonStyle(.plain)
        }
        .kBottomSheet(isPresented: $isOpen, title: sheetTitle) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(options.indices, id: \.self) { index in
                            let option = options[index]
                            Button {
                                selection = option.value
                                isOpen = false
                            } label: {
                                HStack {
                                    Text(option.label).kText(KTextToken.body)
                                    Spacer()
                                    if option.value == selection {
                                        Image(systemName: "checkmark").foregroundStyle(KColors.brand)
                                    }
                                }
                                .padding(.horizontal, KSpace.xl)
                                .padding(.vertical, KSpace.md)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .id(index)
                            Divider().padding(.leading, KSpace.xl)
                        }
                    }
                }
                .onAppear {
                    if let current = options.firstIndex(where: { $0.value == selection }) { proxy.scrollTo(current, anchor: .center) }
                }
            }
        }
    }
}
