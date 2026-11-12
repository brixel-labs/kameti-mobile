import Foundation

/// What Profile shows, kept on the phone per account so the screen opens
/// instantly without calling the server. It's filled after sign-in, updated
/// whenever the app saves or reloads something it holds, refreshed by pull to
/// refresh, and cleared on sign-out.
public struct ProfileSnapshot: Codable, Sendable, Equatable {
    public struct SignIn: Codable, Sendable, Equatable {
        public let provider: String
        public let email: String?
    }

    public var profile: Profile?
    public var kametis: [Kameti]?
    public var people: [Contact]?
    public var signIns: [SignIn]?
    public var notificationPreferences: NotificationPreferences?
    /// Set once the "What should we call you?" prompt was shown after sign-in.
    public var namePrompted: Bool?
    public var savedAt: Date?

    public init() {}

    public var signInMethods: [SignInMethod]? {
        signIns?.compactMap { item in SignInMethod.Provider(rawValue: item.provider).map { SignInMethod(provider: $0, email: item.email) } }
    }
}

public enum ProfileCache {
    private static var defaults: UserDefaults { .standard }
    private static func key(_ userId: String) -> String { "kameti.profileCache.\(userId)" }

    public static func load(userId: String) -> ProfileSnapshot {
        guard let data = defaults.data(forKey: key(userId)),
              let snapshot = try? JSONDecoder().decode(ProfileSnapshot.self, from: data)
        else { return ProfileSnapshot() }
        return snapshot
    }

    /// Reads, changes and writes back the cached snapshot.
    public static func update(userId: String, _ change: (inout ProfileSnapshot) -> Void) {
        var snapshot = load(userId: userId)
        change(&snapshot)
        snapshot.savedAt = Date()
        if let data = try? JSONEncoder().encode(snapshot) { defaults.set(data, forKey: key(userId)) }
    }

    public static func setSignInMethods(userId: String, _ methods: [SignInMethod]) {
        update(userId: userId) { $0.signIns = methods.map { .init(provider: $0.provider.rawValue, email: $0.email) } }
    }

    public static func clear(userId: String) {
        defaults.removeObject(forKey: key(userId))
    }
}
