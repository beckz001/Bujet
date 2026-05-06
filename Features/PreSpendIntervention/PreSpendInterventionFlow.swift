import Foundation
import Observation

/// One enum-driven step at a time. Sheet's `NavigationStack` renders whichever
/// step is current.
enum PreSpendInterventionStep: Hashable {
    case input
    case decision
    case waitConfirmed(InterventionWaitDuration)
    case potCreated(Goal)
}

@MainActor
@Observable
final class PreSpendInterventionFlow: Identifiable {
    @ObservationIgnored let id = UUID()
    @ObservationIgnored private let useCase: PreSpendInterventionUseCase
    @ObservationIgnored private let goalRepository: any GoalRepository
    @ObservationIgnored private let onDismissRequested: () -> Void
    @ObservationIgnored private let onPotsChanged: () -> Void
    @ObservationIgnored private let onShowCoachRequested: () -> Void

    var step: PreSpendInterventionStep = .input

    // Input form
    var amountText: String = ""
    var itemDescription: String = ""
    var category: TransactionCategory = .shopping
    var currencyCode: String = "GBP"
    var inputErrorMessage: String?

    // Evaluation
    var isEvaluating: Bool = false
    var decision: InterventionDecision?
    var evaluationErrorMessage: String?

    // Recording the user's chosen action
    var isRecording: Bool = false

    init(
        useCase: PreSpendInterventionUseCase,
        goalRepository: some GoalRepository,
        currencyCode: String = "GBP",
        onPotsChanged: @escaping () -> Void = {},
        onShowCoachRequested: @escaping () -> Void = {},
        onDismissRequested: @escaping () -> Void
    ) {
        self.useCase = useCase
        self.goalRepository = goalRepository
        self.currencyCode = currencyCode
        self.onPotsChanged = onPotsChanged
        self.onShowCoachRequested = onShowCoachRequested
        self.onDismissRequested = onDismissRequested
    }

    var canSubmitInput: Bool {
        !isEvaluating
        && !itemDescription.trimmingCharacters(in: .whitespaces).isEmpty
        && (Double(amountText) ?? 0) > 0
    }

    func submitInput() async {
        inputErrorMessage = nil
        evaluationErrorMessage = nil
        guard let amount = Double(amountText), amount > 0 else {
            inputErrorMessage = "Enter a valid amount."
            return
        }
        let trimmedDescription = itemDescription.trimmingCharacters(in: .whitespaces)
        guard !trimmedDescription.isEmpty else {
            inputErrorMessage = "Add a short description."
            return
        }

        let proposal = InterventionProposal(
            amount: amount,
            itemDescription: trimmedDescription,
            category: category,
            currencyCode: currencyCode
        )

        isEvaluating = true
        defer { isEvaluating = false }

        do {
            decision = try await useCase.evaluate(proposal)
            step = .decision
        } catch {
            evaluationErrorMessage = "Couldn't generate a reflection. Try again in a moment."
        }
    }

    func chooseBuyNow() async {
        guard let decision else { return }
        isRecording = true
        defer { isRecording = false }
        try? await useCase.recordDecision(for: decision, action: .buyNow)
        onDismissRequested()
    }

    func chooseWait(_ duration: InterventionWaitDuration) async {
        guard let decision else { return }
        isRecording = true
        defer { isRecording = false }
        try? await useCase.recordDecision(for: decision, action: .wait(duration))
        step = .waitConfirmed(duration)
    }

    /// Creates a Wishlist Pot from the current decision and records the
    /// "addToPot" intervention action.
    func chooseAddToPot() async {
        guard let decision else { return }
        isRecording = true
        defer { isRecording = false }

        let item = WishlistItem(
            itemName: decision.proposal.itemDescription,
            estimatedCost: decision.proposal.amount,
            category: decision.proposal.category,
            currencyCode: decision.proposal.currencyCode,
            createdFromIntervention: decision.proposal.id
        )
        let goal = Goal(
            name: decision.proposal.itemDescription,
            targetAmount: decision.proposal.amount,
            currencyCode: decision.proposal.currencyCode,
            linkedItem: item
        )

        do {
            try await goalRepository.upsert(goal)
            try? await useCase.recordDecision(for: decision, action: .addToPot(goalID: goal.id))
            onPotsChanged()
            step = .potCreated(goal)
        } catch {
            evaluationErrorMessage = "Couldn't create the pot. Try again."
        }
    }

    func dismiss() {
        onDismissRequested()
    }

    func dismissAndShowCoach() {
        onShowCoachRequested()
        onDismissRequested()
    }
}
