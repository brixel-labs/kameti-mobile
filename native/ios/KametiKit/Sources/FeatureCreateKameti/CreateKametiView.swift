import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// The create-kameti wizard, six steps (boards AC-1 to AC-6, FR-10 to FR-12).
/// Owner only: whoever creates the kameti owns it. The draft lives on the
/// server from step 1, so closing the wizard keeps it.
public struct CreateKametiView: View {
    @Bindable private var model: CreateWizardModel
    private let onStarted: (String) -> Void
    private let onClose: () -> Void
    /// The step on screen and the direction of the move. SwiftUI gives a
    /// removed view the transition it had *before* the change, so the
    /// direction is set first and the step follows on the next turn.
    @State private var shownStep = WizardStep.basics
    @State private var forward = true

    public init(model: CreateWizardModel, onStarted: @escaping (String) -> Void, onClose: @escaping () -> Void) {
        self.model = model
        self.onStarted = onStarted
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .trailing, spacing: KSpace.xs) {
                WizardProgress(step: model.step)
                Text("Step \(model.step.rawValue + 1) of \(WizardStep.allCases.count)", bundle: .module)
                    .kText(KTextToken.subtitle, color: KColors.textSubtitle)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(model.step.rawValue)))
                    .animation(.smooth(duration: 0.35), value: model.step)
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xs)
            ZStack {
                if model.isLoadingDraft {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                stepView(shownStep)
                    .id(shownStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: forward ? .trailing : .leading),
                        removal: .move(edge: forward ? .leading : .trailing)
                    ))
                }
            }
            .frame(maxHeight: .infinity)
            .clipped()
            .onChange(of: model.step) { old, new in
                forward = new.rawValue >= old.rawValue
                Task { @MainActor in
                    withAnimation(.smooth(duration: 0.35)) { shownStep = new }
                }
            }
        }
        .background(KColors.background)
        .kDismissesKeyboard()
        .navigationTitle(model.isResumed ? String(localized: "Finish setting up", bundle: .module) : String(localized: "New kameti", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if model.isAtStart {
                    Button(String(localized: "Close", bundle: .module), systemImage: "xmark", action: onClose)
                } else {
                    Button(String(localized: "Back", bundle: .module), systemImage: "chevron.left") { model.back() }
                }
            }
            // A reopened draft starts mid-way, so it can be closed from any
            // step; everything is already saved on the server.
            if model.isResumed, !model.isAtStart {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Close", bundle: .module), systemImage: "xmark", action: onClose)
                }
            }
        }
        .task { await model.loadOwner() }
        // A reopened draft jumps straight to its step, without sliding through the rest.
        .onChange(of: model.isResumed) { _, resumed in
            if resumed { shownStep = model.step }
        }
        .kMessageSheet(Binding(
            get: { model.failure.map { KSheetMessage(String(localized: "Something went wrong", bundle: .module), message: $0.userMessage, tone: .error) } },
            set: { if $0 == nil { model.clearFailure() } }
        ))
    }
}

private extension CreateKametiView {
    @ViewBuilder func stepView(_ step: WizardStep) -> some View {
        switch step {
        case .basics: BasicsStep(model: model)
        case .dates: DatesStep(model: model)
        case .members: MembersStep(model: model)
        case .slots: SlotsStep(model: model)
        case .order: OrderStep(model: model)
        case .review: ReviewStep(model: model, onStart: onStarted, onSaveDraft: onClose)
        }
    }
}
