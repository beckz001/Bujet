import SwiftUI

struct PreSpendInterventionSheet: View {
    @Bindable var flow: PreSpendInterventionFlow

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.background.ignoresSafeArea()
                content
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { flow.dismiss() }
                        .disabled(flow.isEvaluating || flow.isRecording)
                }
            }
        }
        .interactiveDismissDisabled(flow.isEvaluating || flow.isRecording)
        .sheet(item: $flow.presentedBudgetsViewModel) { vm in
            BudgetsSheet(viewModel: vm)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch flow.step {
        case .input:
            PauseReflectInputView(flow: flow)
        case .decision:
            if let decision = flow.decision {
                PauseReflectDecisionView(flow: flow, decision: decision)
            }
        case .waitConfirmed(let duration):
            WaitConfirmedView(duration: duration, onDone: flow.dismiss)
        case .potCreated(let goal):
            PotCreatedView(goal: goal, onDone: flow.dismissAndShowCoach)
        }
    }

    private var navigationTitle: String {
        switch flow.step {
        case .input:           "Pause & Reflect"
        case .decision:        "Reflect"
        case .waitConfirmed:   "Saved for later"
        case .potCreated:      "Pot created"
        }
    }
}
