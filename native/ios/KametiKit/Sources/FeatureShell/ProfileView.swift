import KametiDomain
import KametiCore
import KametiUI
import SwiftUI

/// Profile and settings (board AF · Profile, icon list option): who you are,
/// notification and appearance settings, account rows, help, and sign out.
public struct ProfileView: View {
    @Bindable private var model: ProfileViewModel
    private let onOpenKameti: (String) -> Void
    private let onOpenPast: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var editingName = false
    @State private var showingPeople = false
    @State private var showingSignIn = false
    @State private var deletingAccount = false
    @State private var confirmingSignOut = false
    @State private var choosingAppearance = false
    @State private var appearanceHeight: CGFloat = 260
    @State private var nameSheetHeight: CGFloat = 200
    @AppStorage(KAppearance.storageKey) private var appearance = KAppearance.system.rawValue
    // Stored on the phone for now; push notifications arrive with the
    // notifications backend, which reads these later.
    @State private var showingNotifications = false

    public init(model: ProfileViewModel, onOpenKameti: @escaping (String) -> Void = { _ in }, onOpenPast: @escaping () -> Void = {}) {
        self.onOpenPast = onOpenPast
        self.model = model
        self.onOpenKameti = onOpenKameti
    }

    /// The website pages the stores require, on Kameti's own site (kameti-mobile/legal-site).
    private static let supportURL = URL(string: "https://kameti.fhbtechservices.com/support")
    private static let privacyURL = URL(string: "https://kameti.fhbtechservices.com/privacy")

    public var body: some View {
        ScrollView {
            VStack(spacing: KSpace.lg) {
                if let profile = model.profile {
                    Button { editingName = true } label: { profileCard(profile) }
                        .buttonStyle(.plain)
                        .accessibilityHint(Text("Edit your name", bundle: .module))
                } else if let failure = model.failure {
                    ContentUnavailableView {
                        Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                    } actions: {
                        Button(String(localized: "Try again", bundle: .module)) { Task { await model.load() } }
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, KSpace.xl)
                }
                group {
                    row(String(localized: "Notifications", bundle: .module), symbol: "bell", tint: .amber,
                        value: PushCenter.shared.isAllowed ? String(localized: "On", bundle: .module) : String(localized: "Off", bundle: .module)) { showingNotifications = true }
                    row(String(localized: "Appearance", bundle: .module), symbol: "moon", tint: .purple,
                        value: (KAppearance(rawValue: appearance) ?? .system).title, isLast: true) { choosingAppearance = true }
                }
                group {
                    row(String(localized: "My people", bundle: .module), symbol: "person.2", tint: .green, value: "\(model.peopleCount)") { showingPeople = true }
                    row(String(localized: "Sign-in methods", bundle: .module), symbol: "key", tint: .grey,
                        value: model.signInMethods.first.map { SignInMethodsSheet.name($0.provider) }) { showingSignIn = true }
                    row(String(localized: "Past kametis", bundle: .module), symbol: "archivebox", tint: .blue, value: "\(model.pastCount)", isLast: true) { onOpenPast() }
                }
                group {
                    row(String(localized: "Support", bundle: .module), symbol: "questionmark.circle", tint: .green) {
                        if let url = Self.supportURL { openURL(url) }
                    }
                    row(String(localized: "Privacy policy", bundle: .module), symbol: "shield", tint: .grey, isLast: true) {
                        if let url = Self.privacyURL { openURL(url) }
                    }
                }
                group {
                    row(String(localized: "Sign out", bundle: .module), symbol: "rectangle.portrait.and.arrow.right", tint: .grey, showsChevron: false) {
                        confirmingSignOut = true
                    }
                    row(String(localized: "Delete account", bundle: .module), symbol: "trash", tint: .red, color: KColors.negative,
                        showsChevron: false, isLast: true) { deletingAccount = true }
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.bottom, KSpace.xl)
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "Profile", bundle: .module))
        .alert(String(localized: "Sign out of Kameti?", bundle: .module), isPresented: $confirmingSignOut) {
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Sign out", bundle: .module), role: .destructive) { Task { await model.signOut() } }
        } message: {
            Text("You'll need to sign in again to see your kametis.", bundle: .module)
        }
        // Sized to its content, so the sheet has no empty space below.
        .kBottomSheet(
            isPresented: $choosingAppearance, title: String(localized: "Appearance", bundle: .module),
            // The shared sheet's title row is about 58 pt (24 above, the title, 12 below).
            detents: [.height(appearanceHeight + 58)]
        ) {
            AppearancePicker(selection: $appearance)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { appearanceHeight = $0 }
        }
        // Sized to its content, so Save sits right under the field.
        .kBottomSheet(isPresented: $editingName, title: String(localized: "Your name", bundle: .module), detents: [.height(nameSheetHeight + 58)]) {
            EditNameSheet(current: model.profile?.displayName ?? "", save: { await model.updateName($0) }) { editingName = false }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { nameSheetHeight = $0 }
        }
        .kBottomSheet(isPresented: $showingSignIn, title: String(localized: "Sign-in methods", bundle: .module), detents: [.medium]) {
            SignInMethodsSheet(methods: model.signInMethods)
        }
        .kBottomSheet(isPresented: $deletingAccount, title: String(localized: "Delete account", bundle: .module), detents: [.large]) {
            DeleteAccountSheet(model: model) { deletingAccount = false }
        }
        .navigationDestination(isPresented: $showingPeople) { PeopleListView(people: model.people) }
        .navigationDestination(isPresented: $showingNotifications) {
            NotificationSettingsView(userId: model.userId, dependencies: model.dependencies)
        }
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    // MARK: Pieces

    private func profileCard(_ profile: Profile) -> some View {
        HStack(spacing: KSpace.lg) {
            KAvatar(name: profile.displayName, colorIndex: 0, size: .large)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName).kText(KTextToken.titleLg)
                Text("\(model.runningCount) kametis run · \(model.memberCount) joined", bundle: .module)
                    .kText(KTextToken.subtitle, color: KColors.textSubtitle)
            }
            Spacer(minLength: KSpace.sm)
            Image(systemName: "chevron.right").foregroundStyle(KColors.textTertiary)
        }
        .padding(KSpace.lg)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.border))
    }

    private func group<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, KSpace.lg)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
            .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.border))
    }

    private enum Tint {
        case amber, blue, purple, green, grey, red

        var colors: (fg: Color, bg: Color) {
            switch self {
            case .amber: (KColors.warning, KColors.warningSubtle)
            case .blue: (KColors.info, KColors.infoSubtle)
            case .purple: (KColors.info, KColors.infoSubtle)
            case .green: (KColors.onBrandSubtle, KColors.brandSubtle)
            case .grey: (KColors.textSecondary, KColors.surfaceSunken)
            case .red: (KColors.negative, KColors.negativeSubtle)
            }
        }
    }

    private func icon(_ symbol: String, _ tint: Tint) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(tint.colors.fg)
            .frame(width: 30, height: 30)
            .background(tint.colors.bg, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)
    }

    private func row(
        _ title: String, symbol: String, tint: Tint, value: String? = nil, color: Color = KColors.textPrimary,
        showsChevron: Bool = true, isLast: Bool = false, action: (() -> Void)? = nil
    ) -> some View {
        Button { action?() } label: {
            VStack(spacing: 0) {
                HStack(spacing: KSpace.md) {
                    icon(symbol, tint)
                    Text(title).kText(KTextToken.body, color: color)
                    Spacer(minLength: KSpace.sm)
                    if let value { Text(value).kText(KTextToken.subtitle, color: KColors.textSubtitle) }
                    if showsChevron { Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(KColors.textTertiary) }
                }
                .frame(minHeight: 52)
                if !isLast { Divider().padding(.leading, 42) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ title: String, symbol: String, tint: Tint, isOn: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            Toggle(isOn: isOn) {
                HStack(spacing: KSpace.md) {
                    icon(symbol, tint)
                    Text(title).kText(KTextToken.body)
                }
            }
            .toggleStyle(KToggleStyle())
            .frame(minHeight: 52)
            Divider().padding(.leading, 42)
        }
    }
}

/// Appearance as three cards with a small phone preview each (like iOS's
/// Display settings): System, Light and Dark. Tapping one applies it at
/// once; the sheet stays open so the change can be seen and compared.
private struct AppearancePicker: View {
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.lg) {
            HStack(spacing: KSpace.md) {
                ForEach(KAppearance.allCases, id: \.self) { option in
                    card(option)
                }
            }
            Text("System follows your iPhone's setting and switches with it.", bundle: .module)
                .kText(KTextToken.bodySm, color: KColors.textSecondary)
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.top, KSpace.xs)
        .padding(.bottom, KSpace.xl)
    }

    private func card(_ option: KAppearance) -> some View {
        let isOn = selection == option.rawValue
        return Button {
            withAnimation(.smooth(duration: 0.25)) { selection = option.rawValue }
        } label: {
            VStack(spacing: KSpace.sm) {
                preview(option)
                    .frame(height: 116)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isOn ? KColors.brand : KColors.border, lineWidth: isOn ? 2.5 : 1))
                Text(option.title).kText(KTextToken.bodyStrong, color: isOn ? KColors.brand : KColors.textPrimary)
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isOn ? KColors.brand : KColors.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(option.title))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    /// A tiny screen drawn with the app's own colours in that look; System is
    /// half light, half dark.
    @ViewBuilder private func preview(_ option: KAppearance) -> some View {
        switch option {
        case .light: MiniScreen().environment(\.colorScheme, .light)
        case .dark: MiniScreen().environment(\.colorScheme, .dark)
        case .system:
            HStack(spacing: 0) {
                MiniScreen().environment(\.colorScheme, .light)
                MiniScreen().environment(\.colorScheme, .dark)
            }
        }
    }
}

private struct MiniScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Capsule().fill(KColors.textPrimary.opacity(0.85)).frame(width: 28, height: 5)
            RoundedRectangle(cornerRadius: 5).fill(KColors.surface)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Capsule().fill(KColors.brand).frame(width: 22, height: 4)
                        Capsule().fill(KColors.textSecondary.opacity(0.5)).frame(width: 30, height: 3)
                    }
                    .padding(6)
                }
                .frame(height: 34)
            RoundedRectangle(cornerRadius: 5).fill(KColors.surface).frame(height: 22)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(KColors.background)
    }
}
