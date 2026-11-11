import SwiftUI

/// One round action revealed by swiping a `KSwipeRow` left.
public struct KSwipeAction: Identifiable {
    public let id: String
    let label: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    public init(_ label: String, symbol: String, tint: Color, action: @escaping () -> Void) {
        self.id = label; self.label = label; self.symbol = symbol; self.tint = tint; self.action = action
    }
}

/// A card that slides left to reveal round action buttons beside it (like
/// Mail or Files), for rows that aren't in a `List`. It snaps open or shut,
/// and tapping an action closes it first. Rows that share `openRow` open one
/// at a time: sliding one open closes the others, and setting `openRow` to
/// `nil` (a tap elsewhere, a tab change) closes whichever is open.
///
/// It's a sideways scroll view, so it plays well with the vertical scroll
/// around it. Don't put it inside a `.refreshable` scroll view: the refresh
/// control would attach to it too.
public struct KSwipeRow<Content: View>: View {
    private let rowId: String
    @Binding private var openRow: String?
    private let actions: [KSwipeAction]
    private let content: Content
    @State private var width: CGFloat = 0
    /// Drives the row back to its start when it should close.
    @State private var scroll = ScrollPosition(edge: .leading)
    /// Slid open at all (actions partly or fully showing).
    @State private var isOpen = false

    public init(id: String, openRow: Binding<String?>, actions: [KSwipeAction], @ViewBuilder content: () -> Content) {
        self.rowId = id
        _openRow = openRow
        self.actions = actions
        self.content = content()
    }

    private func close() {
        withAnimation(.smooth(duration: 0.25)) { scroll.scrollTo(edge: .leading) }
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: KSpace.md) {
                content
                    .frame(width: max(width, 1))
                HStack(spacing: KSpace.md) {
                    ForEach(actions) { item in
                        Button {
                            close()
                            openRow = nil
                            item.action()
                        } label: {
                            Image(systemName: item.symbol)
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(item.tint, in: Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(item.label))
                    }
                }
                .padding(.trailing, KSpace.xs)
            }
            .scrollTargetLayout()
        }
        .scrollPosition($scroll)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        // Open or not, from how far the row has actually slid. Only really
        // sliding open (not a touch or a swipe right) makes it the open row,
        // which closes the others.
        .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.x > 2 } action: { _, open in
            isOpen = open
            if open, openRow != rowId { openRow = rowId }
            if !open, openRow == rowId { openRow = nil }
        }
        .onChange(of: openRow) { _, open in
            if open != rowId, isOpen { close() }
        }
        // VoiceOver gets the same actions without swiping.
        .accessibilityActions {
            ForEach(actions) { item in
                Button(item.label, action: item.action)
            }
        }
    }
}
