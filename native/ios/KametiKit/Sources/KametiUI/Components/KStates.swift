import Foundation
import KametiCore
import Network
import Observation
import SwiftUI

/// Whether the phone has a connection, watched once for the whole app.
///
/// Two signals: the system's network path, counting only real Wi-Fi,
/// cellular or wired routes (a Mac's virtual bridges, such as Docker's,
/// otherwise keep the simulator "online" with Wi-Fi off); and the app's own
/// requests, so a request that fails for lack of a connection shows the
/// offline state even if the path still looks fine.
@MainActor
@Observable
public final class KConnectivity {
    public static let shared = KConnectivity()

    public var isOnline: Bool { pathOnline && !requestsFailing }
    private var pathOnline = true
    private var requestsFailing = false
    private let monitor = NWPathMonitor()

    private init() {
        monitor.pathUpdateHandler = { path in
            let real = [NWInterface.InterfaceType.wifi, .cellular, .wiredEthernet].contains { path.usesInterfaceType($0) }
            let online = path.status == .satisfied && real
            Task { @MainActor in
                let shared = KConnectivity.shared
                shared.pathOnline = online
                // A fresh connection gets a fresh chance.
                if online { shared.requestsFailing = false }
            }
        }
        monitor.start(queue: DispatchQueue(label: "kameti.connectivity"))
    }

    /// Call after a load: a `.network` failure means offline, success means online.
    public func record(_ failure: Failure?) {
        if failure == .network { requestsFailing = true } else if failure == nil { requestsFailing = false }
    }
}

/// "You're offline. Showing data from 10:42 AM." (board AF-States): shown
/// above a screen whose data is still on screen from the last load.
public struct KOfflineBanner: View {
    private let since: Date?

    public init(since: Date?) { self.since = since }

    private var text: String {
        guard let since else { return String(localized: "You're offline. Some information may be out of date.", bundle: .module) }
        let time = since.formatted(date: .omitted, time: .shortened)
        return String(localized: "You're offline. Showing data from \(time).", bundle: .module)
    }

    public var body: some View {
        Label(text, systemImage: "wifi.slash")
            .kText(KTextToken.bodySm, color: KColors.textSecondary)
            .padding(.horizontal, KSpace.md).padding(.vertical, KSpace.sm + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
    }
}

/// "Can't record payments offline. Connect and try again." (AF-States): in a
/// sheet whose action needs a connection.
public struct KOfflineActionBanner: View {
    private let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        Label(text, systemImage: "exclamationmark.circle")
            .kText(KTextToken.bodySm, color: KColors.negative)
            .padding(.horizontal, KSpace.md).padding(.vertical, KSpace.sm + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KColors.negativeSubtle, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
    }
}

/// Grey placeholder rows while a list loads (AF-States · Loading), instead
/// of a spinner, so the screen keeps its shape.
public struct KSkeletonRows: View {
    private let rows: Int
    @State private var dim = false

    public init(rows: Int = 3) { self.rows = rows }

    public var body: some View {
        VStack(spacing: KSpace.md) {
            ForEach(0..<rows, id: \.self) { index in
                HStack(spacing: KSpace.md) {
                    Circle().fill(KColors.surfaceSunken).frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 6).fill(KColors.surfaceSunken).frame(height: 12)
                            .frame(maxWidth: index.isMultiple(of: 2) ? 180 : 150, alignment: .leading)
                        RoundedRectangle(cornerRadius: 6).fill(KColors.surfaceSunken).frame(width: 110, height: 10)
                    }
                    Spacer()
                    Capsule().fill(KColors.surfaceSunken).frame(width: 56, height: 20)
                }
            }
        }
        .padding(KSpace.lg)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).strokeBorder(KColors.border))
        .opacity(dim ? 0.55 : 1)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: dim)
        .onAppear { dim = true }
        .accessibilityElement()
        .accessibilityLabel(Text("Loading", bundle: .module))
    }
}

/// A centred card with a title, a line of help and an optional action:
/// errors ("Couldn't load this kameti" + Try again), an expired invite, or an
/// empty list (AF-States).
public struct KMessageCard: View {
    private let symbol: String?
    private let tint: Color
    private let title: String
    private let message: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        _ title: String, message: String? = nil, symbol: String? = nil, tint: Color = KColors.textSecondary,
        actionTitle: String? = nil, action: (() -> Void)? = nil
    ) {
        self.title = title; self.message = message; self.symbol = symbol; self.tint = tint
        self.actionTitle = actionTitle; self.action = action
    }

    public var body: some View {
        VStack(spacing: KSpace.sm) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 26, weight: .medium)).foregroundStyle(tint).padding(.bottom, KSpace.xxs)
            }
            Text(title).kText(KTextToken.bodyStrong).multilineTextAlignment(.center)
            if let message {
                Text(message).kText(KTextToken.bodySm, color: KColors.textSecondary).multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).kText(KTextToken.bodyStrong, color: KColors.brand)
                        .padding(.horizontal, KSpace.xl).frame(minHeight: 40)
                        .overlay(Capsule().strokeBorder(KColors.brand))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, KSpace.xs)
            }
        }
        .padding(.vertical, KSpace.xl).padding(.horizontal, KSpace.lg)
        .frame(maxWidth: .infinity)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).strokeBorder(KColors.border))
    }
}

extension Failure {
    /// The help line under an error title: connection advice when offline,
    /// otherwise the failure's own message.
    public var helpMessage: String {
        if self == .network { return String(localized: "Check your connection and try again.", bundle: .module) }
        return userMessage
    }
}
