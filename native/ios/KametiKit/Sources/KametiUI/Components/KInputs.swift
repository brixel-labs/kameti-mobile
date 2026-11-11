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
    private let placeholder: String

    public init(_ title: String, digits: Binding<String>, placeholder: String = "0", error: String? = nil, helper: String? = nil) {
        self.title = title; _digits = digits; self.placeholder = placeholder; self.error = error; self.helper = helper
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
                TextField(placeholder, text: text)
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
                Text(helper).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
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

/// A pill that can be selected. `.filled` turns solid brand colour when on;
/// `.outlined` keeps a light fill with a brand border (the due-day chips).
public struct KChip: View {
    public enum Style: Sendable { case filled, outlined }

    private let title: String
    private let isOn: Bool
    private let style: Style
    private let symbol: String?
    private let action: () -> Void

    public init(_ title: String, symbol: String? = nil, isOn: Bool, style: Style = .filled, action: @escaping () -> Void) {
        self.title = title; self.symbol = symbol; self.isOn = isOn; self.style = style; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: KSpace.xs) {
                if let symbol { Image(systemName: symbol).imageScale(.small).accessibilityHidden(true) }
                Text(title)
            }
                .kText(KTextToken.bodyStrong, color: foreground)
                .padding(.horizontal, KSpace.lg)
                .padding(.vertical, KSpace.sm + 2)
                .background(background, in: Capsule())
                .overlay(Capsule().stroke(isOn ? KColors.brand : KColors.border, lineWidth: isOn && style == .outlined ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var foreground: Color { isOn && style == .filled ? KColors.textOnBrand : KColors.textPrimary }
    private var background: Color {
        guard isOn else { return KColors.surface }
        return style == .filled ? KColors.brand : KColors.brandSubtle
    }
}

/// A rounded-square day tile for a 5-column grid; solid brand colour when on.
public struct KDayTile: View {
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
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(isOn ? KColors.brand : KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(isOn ? KColors.brand : KColors.border))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// A small − value + control for use inside a settings row.
public struct KCompactStepper: View {
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
        HStack(spacing: KSpace.md) {
            square("minus", label: decreaseLabel, enabled: value > range.lowerBound) { onChange(value - 1) }
            Text("\(value)").kText(KTextToken.title).monospacedDigit().frame(minWidth: 20)
            square("plus", label: increaseLabel, enabled: value < range.upperBound) { onChange(value + 1) }
        }
    }

    private func square(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(enabled ? KColors.textPrimary : KColors.textTertiary)
                .frame(width: 40, height: 40)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(KColors.border))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
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
    /// The shared bottom sheet: grabber, a title with a close button and the
    /// content. The grabber is drawn here (not by the system) so every sheet
    /// has the same grabber, title and close position whatever its height.
    func kBottomSheet<Content: View>(
        isPresented: Binding<Bool>, title: String,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented) {
            // A navigation context (bar hidden) so a keyboard toolbar can show in a sheet.
            NavigationStack {
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
                // Same title position with or without a grabber, clear of it.
                .padding(.top, KSpace.xl)
                .padding(.bottom, KSpace.md)
                content()
            }
            .toolbar(.hidden, for: .navigationBar)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .top) {
                // Only a sheet that can be resized shows a grabber.
                if detents.count > 1 {
                    Capsule()
                        .fill(KColors.borderStrong)
                        .frame(width: 40, height: 5)
                        .padding(.top, 14)
                        .accessibilityHidden(true)
                }
            }
            .ignoresSafeArea(.container, edges: .top)
            .background(KColors.background)
            .presentationDetents(detents)
            .presentationDragIndicator(.hidden)
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
                .contentShape(RoundedRectangle(cornerRadius: KRadius.input))
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

/// The design's switch: a green capsule track with a white knob that slides.
/// Use it as `Toggle(isOn:) { label }.toggleStyle(KToggleStyle())`.
public struct KToggleStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: KSpace.md) {
                configuration.label
                Spacer(minLength: KSpace.sm)
                track(isOn: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }

    private func track(isOn: Bool) -> some View {
        Capsule()
            .fill(isOn ? KColors.brand : KColors.borderStrong)
            .frame(width: 52, height: 32)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                    .padding(3)
            }
            .animation(.spring(duration: 0.25, bounce: 0.25), value: isOn)
    }
}

/// A rounded-square checkbox with the label on its trailing side.
/// Use it as `Toggle(isOn:) { label }.toggleStyle(KCheckboxStyle())`.
public struct KCheckboxStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: KSpace.sm) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(configuration.isOn ? KColors.brand : KColors.surface)
                    .frame(width: 26, height: 26)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(configuration.isOn ? KColors.brand : KColors.borderStrong, lineWidth: 1.5))
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(KColors.textOnBrand)
                            .opacity(configuration.isOn ? 1 : 0)
                            .scaleEffect(configuration.isOn ? 1 : 0.5)
                    }
                    .animation(.spring(duration: 0.25, bounce: 0.3), value: configuration.isOn)
                configuration.label
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }
}

/// A compact action capsule. `.tonal` is the secondary action (light green
/// with green text); `.neutral` is white with a grey border. Primary is the
/// filled green capsule.
public struct KTonalButton: View {
    public enum Style: Sendable { case tonal, neutral }

    private let title: String
    private let symbol: String?
    private let style: Style
    private let action: () -> Void

    public init(_ title: String, symbol: String? = nil, style: Style = .tonal, action: @escaping () -> Void) {
        self.title = title; self.symbol = symbol; self.style = style; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol { Image(systemName: symbol).font(.system(size: 13, weight: .semibold)).accessibilityHidden(true) }
                Text(title)
            }
            .kText(KTextStyle(size: 13, weight: .semibold), color: style == .tonal ? KColors.onBrandSubtle : KColors.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(style == .tonal ? KColors.brandSubtle : KColors.surface, in: Capsule())
            .overlay(Capsule().stroke(KColors.border).opacity(style == .neutral ? 1 : 0))
        }
        .buttonStyle(.plain)
    }
}

/// The six-dot drag handle (two columns of three) in a light rounded square.
public struct KGripHandle: View {
    private let boxed: Bool

    public init(boxed: Bool = true) { self.boxed = boxed }

    public var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 4) {
                    Circle().frame(width: 3.5, height: 3.5)
                    Circle().frame(width: 3.5, height: 3.5)
                }
            }
        }
        .foregroundStyle(KColors.textTertiary)
        .frame(width: 36, height: 36)
        .background(boxed ? KColors.surfaceSunken : .clear, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityHidden(true)
    }
}

/// Tabs with an underline that slides under the selected one. Pair it with
/// content that slides the same way (see `OwnerTabs`).
///
/// Every tab is the same width (the widest title plus padding). When they fit
/// they share the full width; when they don't, the row scrolls sideways and
/// keeps the selected tab in view.
public struct KUnderlineTabs<Tab: Hashable>: View {
    private let tabs: [(tab: Tab, title: String)]
    private let inset: CGFloat
    @Binding private var selection: Tab
    @Namespace private var underline
    @State private var available: CGFloat = 0
    /// The row's measured height: a horizontal scroll view has none of its own.
    @State private var rowHeight: CGFloat = 44

    /// `inset` pads the tabs from the screen edges while the divider under
    /// them still runs the full width.
    public init(_ tabs: [(tab: Tab, title: String)], selection: Binding<Tab>, inset: CGFloat = 0) {
        self.tabs = tabs; _selection = selection; self.inset = inset
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                EqualWidthRow(minItemWidth: tabs.isEmpty ? 0 : max(available - 2 * inset, 0) / CGFloat(tabs.count)) {
                    ForEach(tabs.indices, id: \.self) { index in
                        tabButton(tabs[index]).id(index)
                    }
                }
                .padding(.horizontal, inset)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowHeight = $0 }
            }
            .frame(height: rowHeight)
            // Sideways only: never bounce up and down.
            .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
            // This small row must not become the scroll view the navigation
            // bar tracks: that pushed its content down out of sight.
            .scrollEdgeEffectHidden(true, for: .all)
            .onChange(of: selection) { _, new in
                guard let index = tabs.firstIndex(where: { $0.tab == new }) else { return }
                withAnimation(.smooth(duration: 0.28)) { proxy.scrollTo(index, anchor: .center) }
            }
        }
        // The top spacing sits outside the scroll view, so the scroll view
        // never touches the navigation bar's edge.
        .padding(.top, KSpace.sm)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { available = $0 }
        .background(alignment: .bottom) { Rectangle().fill(KColors.border).frame(height: 1) }
    }

    private func tabButton(_ item: (tab: Tab, title: String)) -> some View {
        let isOn = item.tab == selection
        return Button {
            withAnimation(.smooth(duration: 0.28)) { selection = item.tab }
        } label: {
            VStack(spacing: 10) {
                Text(item.title)
                    .kText(KTextToken.bodyStrong, color: isOn ? KColors.brand : KColors.textSecondary)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, KSpace.md)
                ZStack {
                    Rectangle().fill(.clear).frame(height: 2.5)
                    if isOn {
                        Capsule().fill(KColors.brand).frame(height: 2.5)
                            .matchedGeometryEffect(id: "underline", in: underline)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Lays children side by side, all as wide as the widest one (and at least
/// `minItemWidth`), so tabs are equal.
private struct EqualWidthRow: Layout {
    let minItemWidth: CGFloat

    private func itemWidth(_ subviews: Subviews) -> CGFloat {
        let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        return max(widest, minItemWidth)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = itemWidth(subviews)
        let height = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height }.max() ?? 0
        return CGSize(width: width * CGFloat(subviews.count), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = itemWidth(subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + CGFloat(index) * width, y: bounds.minY),
                proposal: ProposedViewSize(width: width, height: bounds.height)
            )
        }
    }
}

/// A segmented control in the design's look: a light track with a white,
/// sliding selection.
public struct KSegmented<Value: Hashable>: View {
    private let options: [(value: Value, title: String)]
    @Binding private var selection: Value
    @Namespace private var slider

    public init(_ options: [(value: Value, title: String)], selection: Binding<Value>) {
        self.options = options; _selection = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let isOn = option.value == selection
                Button {
                    withAnimation(.smooth(duration: 0.22)) { selection = option.value }
                } label: {
                    Text(option.title)
                        .kText(KTextStyle(size: 14, weight: isOn ? .semibold : .medium), color: isOn ? KColors.textPrimary : KColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background {
                            if isOn {
                                RoundedRectangle(cornerRadius: 9).fill(KColors.surface)
                                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                                    .matchedGeometryEffect(id: "selection", in: slider)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(4)
        .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: 12))
    }
}
