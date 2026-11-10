import SwiftUI
import UIKit

/// A vertically scrolling list of SwiftUI rows the user can reorder with the
/// system's own interactive movement: press and hold a row, then drag; it
/// lifts, the others move aside, and it settles with the system animation.
/// Rows are identified by string ids; `ids` is updated when a move finishes.
public struct KReorderList<Row: View>: UIViewRepresentable {
    @Binding private var ids: [String]
    private let row: (Int, String) -> Row

    public init(ids: Binding<[String]>, @ViewBuilder row: @escaping (Int, String) -> Row) {
        _ids = ids
        self.row = row
    }

    public func makeCoordinator() -> Coordinator { Coordinator(ids: $ids, row: { AnyView(row($0, $1)) }) }

    public func makeUIView(context: Context) -> UICollectionView {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        configuration.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.allowsSelection = false
        view.contentInset.bottom = 16
        view.alwaysBounceVertical = true
        context.coordinator.attach(to: view)
        return view
    }

    public func updateUIView(_ view: UICollectionView, context: Context) {
        context.coordinator.row = { AnyView(row($0, $1)) }
        context.coordinator.apply(ids: ids)
    }

    @MainActor
    public final class Coordinator: NSObject {
        private var ids: Binding<[String]>
        var row: (Int, String) -> AnyView
        private var dataSource: UICollectionViewDiffableDataSource<Int, String>?
        private weak var collectionView: UICollectionView?
        private var isMoving = false

        init(ids: Binding<[String]>, row: @escaping (Int, String) -> AnyView) {
            self.ids = ids
            self.row = row
        }

        func attach(to view: UICollectionView) {
            collectionView = view
            let registration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { [weak self] cell, _, id in
                guard let self else { return }
                let index = self.dataSource?.snapshot().itemIdentifiers.firstIndex(of: id) ?? 0
                cell.backgroundConfiguration = .clear()
                cell.contentConfiguration = UIHostingConfiguration { self.row(index, id).padding(.vertical, 4) }
                    .margins(.horizontal, 20)
                    .margins(.vertical, 0)
            }
            let source = UICollectionViewDiffableDataSource<Int, String>(collectionView: view) { collection, indexPath, id in
                collection.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: id)
            }
            source.reorderingHandlers.canReorderItem = { _ in true }
            source.reorderingHandlers.didReorder = { [weak self] transaction in
                guard let self else { return }
                self.ids.wrappedValue = transaction.finalSnapshot.itemIdentifiers
            }
            dataSource = source
            let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
            press.minimumPressDuration = 0.25
            view.addGestureRecognizer(press)
            apply(ids: ids.wrappedValue, animated: false)
        }

        func apply(ids newIds: [String], animated: Bool = true) {
            guard let dataSource, !isMoving else { return }
            var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
            snapshot.appendSections([0])
            snapshot.appendItems(newIds)
            // Row numbers and names can change without the ids changing.
            snapshot.reconfigureItems(newIds)
            dataSource.apply(snapshot, animatingDifferences: animated)
        }

        @objc private func handlePress(_ gesture: UILongPressGestureRecognizer) {
            guard let view = collectionView else { return }
            let location = gesture.location(in: view)
            switch gesture.state {
            case .began:
                guard let indexPath = view.indexPathForItem(at: location) else { return }
                isMoving = view.beginInteractiveMovementForItem(at: indexPath)
                if isMoving { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            case .changed:
                if isMoving { view.updateInteractiveMovementTargetPosition(location) }
            case .ended:
                if isMoving { view.endInteractiveMovement() }
                finishMoving()
            default:
                if isMoving { view.cancelInteractiveMovement() }
                finishMoving()
            }
        }

        private func finishMoving() {
            isMoving = false
            // Refresh row numbers after the drop.
            apply(ids: ids.wrappedValue, animated: false)
        }
    }
}
