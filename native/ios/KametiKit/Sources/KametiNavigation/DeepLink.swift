import Foundation

/// Turns an opened URL into a route. Only the invite link exists today:
/// `https://www.fhbtechservices.com/kameti/join/<token>`.
public enum DeepLink {
    static let hosts: Set<String> = ["www.fhbtechservices.com", "fhbtechservices.com"]

    public static func route(for url: URL) -> Route? {
        guard url.scheme == "https", let host = url.host()?.lowercased(), hosts.contains(host) else {
            return nil
        }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 3, parts[0] == "kameti", parts[1] == "join", !parts[2].isEmpty else {
            return nil
        }
        return .join(token: parts[2])
    }
}
