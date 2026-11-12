import Foundation
import Observation

/// The app-wide "something changed" signal. Live changes (and coming back to
/// the app) bump `revision`; screens watch it and reload quietly, without a
/// spinner. Bursts of changes are folded into one reload.
@MainActor
@Observable
public final class KLiveUpdates {
    public static let shared = KLiveUpdates()

    /// Goes up once per batch of changes.
    public private(set) var revision = 0
    /// Kametis changed in the last batch; `nil` means "anything may have".
    public private(set) var changedKametiIds: Set<String>?

    @ObservationIgnored private var pending: Set<String>? = []
    @ObservationIgnored private var flush: Task<Void, Never>?

    public init() {}

    /// A change arrived; `kametiId` nil means it can't be pinned to one kameti.
    public func record(kametiId: String?) {
        if let kametiId { pending?.insert(kametiId) } else { pending = nil }
        guard flush == nil else { return }
        flush = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            self?.publish()
        }
    }

    /// Back in the app: everything may have changed.
    public func refreshAll() {
        pending = nil
        publish()
    }

    /// Whether the last batch touches this kameti.
    public func affects(_ kametiId: String) -> Bool {
        changedKametiIds?.contains(kametiId) ?? true
    }

    private func publish() {
        flush?.cancel()
        flush = nil
        changedKametiIds = pending
        pending = []
        revision += 1
    }
}
