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
    @ObservationIgnored private let budgetRepository: any BudgetRepository
    @ObservationIgnored private let transactionRepository: any TransactionRepository
    @ObservationIgnored private let waitReminderScheduler: WaitReminderScheduler
    @ObservationIgnored private let onDismissRequested: () -> Void
    @ObservationIgnored private let onPotsChanged: () -> Void
    @ObservationIgnored private let onTransactionsChanged: () -> Void
    @ObservationIgnored private let onShowCoachRequested: () -> Void

    var step: PreSpendInterventionStep = .input

    // Input form
    var amountText: String = ""
    var itemDescription: String = ""
    var category: TransactionCategory = .shopping
    var currencyCode: String = "GBP"
    var inputErrorMessage: String?

    // No-budget alert state
    var noBudgetCategory: TransactionCategory?
    /// Set when the user taps "Set a budget" — drives a sheet-on-sheet
    /// presentation of `BudgetsSheet` from inside this flow.
    var presentedBudgetsViewModel: BudgetsViewModel?

    // Evaluation
    var isEvaluating: Bool = false
    var decision: InterventionDecision?
    var evaluationErrorMessage: String?

    // Recording the user's chosen action
    var isRecording: Bool = false

    init(
        useCase: PreSpendInterventionUseCase,
        goalRepository: some GoalRepository,
        budgetRepository: some BudgetRepository,
        transactionRepository: some TransactionRepository,
        waitReminderScheduler: WaitReminderScheduler = WaitReminderScheduler(),
        currencyCode: String = "GBP",
        onPotsChanged: @escaping () -> Void = {},
        onTransactionsChanged: @escaping () -> Void = {},
        onShowCoachRequested: @escaping () -> Void = {},
        onDismissRequested: @escaping () -> Void
    ) {
        self.useCase = useCase
        self.goalRepository = goalRepository
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
        self.waitReminderScheduler = waitReminderScheduler
        self.currencyCode = currencyCode
        self.onPotsChanged = onPotsChanged
        self.onTransactionsChanged = onTransactionsChanged
        self.onShowCoachRequested = onShowCoachRequested
        self.onDismissRequested = onDismissRequested
    }

    var canSubmitInput: Bool {
        !isEvaluating
        && !itemDescription.trimmingCharacters(in: .whitespaces).isEmpty
        && (Double(amountText) ?? 0) > 0
    }

    /// First step of the input flow. If no budget is set for the chosen
    /// category we surface a friendly alert before evaluating, since the
    /// reflection lands much more meaningfully against a budget.
    func submitInput() async {
        inputErrorMessage = nil
        evaluationErrorMessage = nil
        guard validateInput() else { return }

        let book = await budgetRepository.fetch()
        if !book.hasLimit(for: category) {
            noBudgetCategory = category
            return
        }

        await runEvaluation()
    }

    /// Continue past the no-budget alert without setting one.
    func continueWithoutBudget() async {
        noBudgetCategory = nil
        await runEvaluation()
    }

    /// User opted to set a budget — present the BudgetsSheet on top of this
    /// sheet. The flow itself stays put with all input intact, so on save the
    /// user just taps Reflect again.
    func requestSetBudget() {
        noBudgetCategory = nil
        presentedBudgetsViewModel = BudgetsViewModel(
            budgetRepository: budgetRepository,
            currencyCode: currencyCode,
            onSaved: { [weak self] in
                self?.presentedBudgetsViewModel = nil
            }
        )
    }

    private func validateInput() -> Bool {
        guard (Double(amountText) ?? 0) > 0 else {
            inputErrorMessage = "Enter a valid amount."
            return false
        }
        let trimmed = itemDescription.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            inputErrorMessage = "Add a short description."
            return false
        }
        itemDescription = trimmed
        return true
    }

    private func makeProposal() -> InterventionProposal? {
        guard let amount = Double(amountText), amount > 0 else { return nil }
        let trimmed = itemDescription.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return InterventionProposal(
            amount: amount,
            itemDescription: trimmed,
            category: category,
            currencyCode: currencyCode
        )
    }

    private func runEvaluation() async {
        guard let proposal = makeProposal() else { return }

        isEvaluating = true
        defer { isEvaluating = false }

        do {
            decision = try await useCase.evaluate(proposal)
            step = .decision
        } catch {
            evaluationErrorMessage = "Couldn't generate a reflection. Try again in a moment."
        }
    }

    /// Persist Buy now both as an intervention log AND as an actual transaction
    /// so the user's spending records reflect what they did.
    func chooseBuyNow() async {
        guard let decision else { return }
        isRecording = true
        defer { isRecording = false }

        try? await useCase.recordDecision(for: decision, action: .buyNow)
        await persistBuyNowTransaction(for: decision)
        onTransactionsChanged()
        onDismissRequested()
    }

    func chooseWait(_ duration: InterventionWaitDuration) async {
        guard let decision else { return }
        isRecording = true
        defer { isRecording = false }

        try? await useCase.recordDecision(for: decision, action: .wait(duration))
        await waitReminderScheduler.schedule(
            for: decision.proposal,
            duration: duration
        )
        step = .waitConfirmed(duration)
    }

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

    // MARK: - Helpers

    private func persistBuyNowTransaction(for decision: InterventionDecision) async {
        let transaction = Transaction(
            id: "intervention-\(decision.proposal.id.uuidString)",
            date: .now,
            description: decision.proposal.itemDescription,
            merchantName: decision.proposal.itemDescription,
            amount: -abs(decision.proposal.amount),
            currencyCode: decision.proposal.currencyCode,
            source: .manual,
            category: decision.proposal.category
        )
        try? await transactionRepository.add([transaction])
    }
}
