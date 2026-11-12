import Foundation

/// A row changed on the server (a payment, a member, a notification…).
public struct LiveChange: Sendable, Equatable {
    public let table: String
    /// The kameti it belongs to, when the row says so.
    public let kametiId: String?

    public init(table: String, kametiId: String?) {
        self.table = table; self.kametiId = kametiId
    }
}

/// Live updates from the backend, so screens refresh themselves.
public protocol LiveUpdatesRepository: Sendable {
    /// Starts listening; `onChange` is called for every change the user may see.
    func start(onChange: @escaping @Sendable (LiveChange) -> Void) async
    func stop() async
}

/// For builds without a backend: nothing ever changes on its own.
public struct UnavailableLiveUpdates: LiveUpdatesRepository {
    public init() {}
    public func start(onChange: @escaping @Sendable (LiveChange) -> Void) async {}
    public func stop() async {}
}
