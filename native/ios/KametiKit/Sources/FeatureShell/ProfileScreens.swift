import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Edit the name other people see (1–80 characters), with Save pinned at the
/// bottom like the app's other sheets.
struct EditNameSheet: View {
    let current: String
    let save: (String) async -> Failure?
    let onDone: () -> Void

    @State private var name: String
    @State private var isBusy = false
    @State private var failure: Failure?
    @FocusState private var focused: Bool

    init(current: String, save: @escaping (String) async -> Failure?, onDone: @escaping () -> Void) {
        self.current = current
        self.save = save
        self.onDone = onDone
        _name = State(initialValue: current)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { (1...80).contains(trimmed.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.md) {
            TextField(String(localized: "Your name", bundle: .module), text: $name)
                .textInputAutocapitalization(.words)
                .focused($focused)
                .padding(.horizontal, KSpace.md)
                .frame(minHeight: 48)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isValid || name.isEmpty ? KColors.border : KColors.negative))
            Text("Members see this name on kametis you run, and owners see it when you join.", bundle: .module)
                .kText(KTextToken.bodySm, color: KColors.textSecondary)
            if let failure {
                Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
            }
            Button(action: submit) {
                ZStack {
                    Text("Save", bundle: .module).opacity(isBusy ? 0 : 1)
                    if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                }
                .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            .disabled(!isValid || trimmed == current)
            .allowsHitTesting(!isBusy)
            .padding(.top, KSpace.sm)
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.top, KSpace.xxs)
        .padding(.bottom, KSpace.lg)
        .onAppear { focused = true }
    }

    private func submit() {
        isBusy = true
        failure = nil
        Task {
            let result = await save(trimmed)
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }
}

/// Which sign-in methods the account has, and the email each uses.
struct SignInMethodsSheet: View {
    let methods: [SignInMethod]

    static func name(_ provider: SignInMethod.Provider) -> String {
        switch provider {
        case .apple: String(localized: "Apple", bundle: .module)
        case .google: String(localized: "Google", bundle: .module)
        case .email: String(localized: "Email", bundle: .module)
        }
    }

    private func symbol(_ provider: SignInMethod.Provider) -> String {
        switch provider {
        case .apple: "apple.logo"
        case .google: "g.circle.fill"
        case .email: "envelope.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.md) {
            if methods.isEmpty {
                Text("We couldn't read your sign-in methods. Pull down on Profile to try again.", bundle: .module)
                    .kText(KTextToken.body, color: KColors.textSecondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(methods.enumerated()), id: \.offset) { index, method in
                        HStack(spacing: KSpace.md) {
                            Image(systemName: symbol(method.provider))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(KColors.textPrimary)
                                .frame(width: 32, height: 32)
                                .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Self.name(method.provider)).kText(KTextToken.bodyStrong)
                                if let email = method.email {
                                    Text(email).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                                }
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(KColors.positive)
                        }
                        .padding(.vertical, KSpace.md)
                        if index < methods.count - 1 { Divider() }
                    }
                }
                .padding(.horizontal, KSpace.lg)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
                .overlay(RoundedRectangle(cornerRadius: KRadius.card).strokeBorder(KColors.border))
                Text("Invites are matched to the email you sign in with. If it's different from the one an owner used, they'll approve you first.", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.top, KSpace.xxs)
    }
}

/// "My people": the owner's saved people, picked from when adding members.
struct PeopleListView: View {
    let people: [Contact]
    @State private var search = ""

    private var shown: [Contact] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return people }
        return people.filter {
            $0.name.localizedCaseInsensitiveContains(query) || ($0.email ?? "").localizedCaseInsensitiveContains(query) || ($0.phone ?? "").contains(query)
        }
    }

    var body: some View {
        Group {
            if people.isEmpty {
                ContentUnavailableView(
                    String(localized: "No saved people yet", bundle: .module), systemImage: "person.2",
                    description: Text("People you add to a kameti are saved here, so next time you can pick them.", bundle: .module)
                )
            } else {
                List(shown) { person in
                    HStack(spacing: KSpace.md) {
                        KAvatar(name: person.name, colorIndex: person.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 6, size: .medium)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name).kText(KTextToken.bodyStrong)
                            Text(person.email ?? person.phone ?? String(localized: "No email or phone", bundle: .module))
                                .kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $search, prompt: Text("Search people", bundle: .module))
            }
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "My people", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Completed, archived and cancelled kametis; each opens its read-only view.
struct PastKametisView: View {
    let kametis: [Kameti]
    let onOpen: (String) -> Void

    var body: some View {
        Group {
            if kametis.isEmpty {
                ContentUnavailableView(
                    String(localized: "No past kametis", bundle: .module), systemImage: "archivebox",
                    description: Text("Kametis that finish or are archived move here.", bundle: .module)
                )
            } else {
                List(kametis) { kameti in
                    Button { onOpen(kameti.id) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(kameti.name).kText(KTextToken.bodyStrong)
                                Text(status(kameti)).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(KColors.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "Past kametis", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func status(_ kameti: Kameti) -> String {
        let months = String(localized: "\(kameti.monthsN) months · \(kameti.slotAmountC.format()) per slot", bundle: .module)
        switch kameti.status {
        case .completed: return String(localized: "Completed", bundle: .module) + " · " + months
        case .archived: return String(localized: "Archived", bundle: .module) + " · " + months
        case .cancelled: return String(localized: "Cancelled", bundle: .module) + " · " + months
        default: return months
        }
    }
}

/// Delete account (REQUIREMENTS §5.5): asks the backend what would happen,
/// then either lists the running kametis that block it, or explains what is
/// deleted and kept and asks the user to type DELETE before going ahead.
struct DeleteAccountSheet: View {
    let model: ProfileViewModel
    let onClose: () -> Void

    @State private var check: Result<AccountDeletionCheck, Failure>?
    @State private var typed = ""
    @State private var isDeleting = false
    @State private var failure: Failure?

    private static let word = "DELETE"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                switch check {
                case .none:
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, KSpace.xxl)
                case .failure(let failure):
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.body, color: KColors.negative)
                    Button(String(localized: "Try again", bundle: .module)) { Task { await load() } }
                case .success(let check) where !check.canDelete:
                    blocked(check)
                case .success(let check):
                    allowed(check)
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xxs)
            .padding(.bottom, KSpace.xl)
        }
        .kDismissesKeyboard()
        .task { await load() }
    }

    private func load() async {
        check = nil
        check = await model.deletionCheck()
    }

    // MARK: Blocked

    private func blocked(_ check: AccountDeletionCheck) -> some View {
        VStack(alignment: .leading, spacing: KSpace.lg) {
            Label(String(localized: "You still run a kameti", bundle: .module), systemImage: "lock.fill")
                .kText(KTextToken.title, color: KColors.warning)
            Text("Other people's money is still being recorded in these, so your account can't be deleted yet. Archive them or hand them over to someone else first.", bundle: .module)
                .kText(KTextToken.body, color: KColors.textSecondary)
            card {
                ForEach(Array(check.blockingKametis.enumerated()), id: \.element.id) { index, kameti in
                    HStack {
                        Text(kameti.name).kText(KTextToken.bodyStrong)
                        Spacer()
                        KPill(String(localized: "Running", bundle: .module), foreground: KColors.positive, background: KColors.positiveSubtle)
                    }
                    .padding(.vertical, KSpace.md)
                    if index < check.blockingKametis.count - 1 { Divider() }
                }
            }
            Button(action: onClose) {
                Text("OK", bundle: .module).kText(KTextToken.bodyStrong).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }

    // MARK: Allowed

    private func allowed(_ check: AccountDeletionCheck) -> some View {
        VStack(alignment: .leading, spacing: KSpace.lg) {
            Text("This can't be undone.", bundle: .module).kText(KTextToken.title, color: KColors.negative)
            card {
                VStack(alignment: .leading, spacing: KSpace.md) {
                    point("trash", String(localized: "Your sign-in and profile are deleted.", bundle: .module))
                    if !check.draftsToDelete.isEmpty {
                        point("doc.badge.ellipsis", check.draftsToDelete.count == 1
                              ? String(localized: "1 draft kameti is deleted.", bundle: .module)
                              : String(localized: "\(check.draftsToDelete.count) draft kametis are deleted.", bundle: .module))
                    }
                    if check.contactsToDelete > 0 {
                        point("person.2", String(localized: "Your \(check.contactsToDelete) saved people are deleted.", bundle: .module))
                    }
                    if check.membershipsToUnlink > 0 {
                        point("link", String(localized: "You're removed from the app in \(check.membershipsToUnlink) kametis you joined. Your payments stay in those owners' records.", bundle: .module))
                    }
                    if !check.ownedKametisKept.isEmpty {
                        point("archivebox", String(localized: "Your past kametis stay for their members, shown as \"Deleted account\".", bundle: .module))
                    }
                }
                .padding(.vertical, KSpace.md)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Type \(Self.word) to confirm", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
                TextField(Self.word, text: $typed)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, KSpace.md)
                    .frame(minHeight: 48)
                    .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.border))
            }
            if let failure {
                Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
            }
            Button(action: delete) {
                ZStack {
                    Text("Delete my account", bundle: .module).opacity(isDeleting ? 0 : 1)
                    if isDeleting { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                }
                .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.negative)
            .controlSize(.large)
            .disabled(typed.trimmingCharacters(in: .whitespaces).uppercased() != Self.word)
            .allowsHitTesting(!isDeleting)
        }
    }

    private func point(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text).kText(KTextToken.body).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol).foregroundStyle(KColors.textSecondary)
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(.horizontal, KSpace.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
            .overlay(RoundedRectangle(cornerRadius: KRadius.card).strokeBorder(KColors.border))
    }

    private func delete() {
        kDismissKeyboard()
        isDeleting = true
        failure = nil
        Task {
            let result = await model.deleteAccount()
            isDeleting = false
            if let result { failure = result } else { onClose() }
        }
    }
}
