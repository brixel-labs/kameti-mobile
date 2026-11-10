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
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(model.step.rawValue)))
                    .animation(.smooth(duration: 0.35), value: model.step)
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xs)
            ZStack {
                stepView(shownStep)
                    .id(shownStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: forward ? .trailing : .leading),
                        removal: .move(edge: forward ? .leading : .trailing)
                    ))
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
        .navigationTitle(String(localized: "New kameti", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if model.isAtStart {
                    Button(String(localized: "Close", bundle: .module), systemImage: "xmark", action: onClose)
                } else {
                    Button(String(localized: "Back", bundle: .module), systemImage: "chevron.left") { model.back() }
                }
            }
        }
        .task { await model.loadOwner() }
        .alert(
            model.failure?.userMessage ?? "",
            isPresented: Binding(get: { model.failure != nil }, set: { if !$0 { model.clearFailure() } })
        ) {
            Button(String(localized: "OK", bundle: .module), role: .cancel) {}
        }
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
