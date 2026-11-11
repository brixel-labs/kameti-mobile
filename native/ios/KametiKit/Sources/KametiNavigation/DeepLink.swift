import Foundation

/// Turns an opened URL into a route. Only invite links exist today:
/// - `https://kameti.fhbtechservices.com/join/<token>` (Kameti's own site, current);
/// - `https://www.fhbtechservices.com/kameti/join/<token>` (the first links sent,
///   which still work and redirect to the new site).
public enum DeepLink {
    static let siteHost = "kameti.fhbtechservices.com"
    static let legacyHosts: Set<String> = ["www.fhbtechservices.com", "fhbtechservices.com"]

    public static func route(for url: URL) -> Route? {
        guard url.scheme == "https", let host = url.host()?.lowercased() else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        let token: String?
        if host == siteHost, parts.count == 2, parts[0] == "join" {
            token = parts[1]
        } else if legacyHosts.contains(host), parts.count == 3, parts[0] == "kameti", parts[1] == "join" {
            token = parts[2]
        } else {
            token = nil
        }
        guard let token, !token.isEmpty else { return nil }
        return .join(token: token)
    }
}
