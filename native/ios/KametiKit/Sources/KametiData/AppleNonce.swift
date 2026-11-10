import CryptoKit
import Foundation

/// The nonce pair Sign in with Apple needs: Apple gets the SHA-256 hash, and
/// Supabase gets the raw value to check the token against.
public struct AppleNonce: Sendable, Equatable {
    public let raw: String
    public let hashed: String

    public init(raw: String) {
        self.raw = raw
        hashed = Self.sha256Hex(raw)
    }

    /// 32 random bytes, URL-safe base64.
    public static func make() -> AppleNonce {
        var bytes = [UInt8](repeating: 0, count: 32)
        for index in bytes.indices { bytes[index] = UInt8.random(in: .min ... .max) }
        let raw = Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return AppleNonce(raw: raw)
    }

    static func sha256Hex(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
