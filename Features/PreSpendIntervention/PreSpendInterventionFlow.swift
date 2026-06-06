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

/// # PreSpendInterventionFlow
///
/// **What it is** — the observable state-and-coordination object behind the
/// "Pause & Reflect" sheet: the screen-state model that owns one run of the
/// pre-spend intervention, from typing in a purchase to choosing what to do
/// about it.
///
/// **What it does** — it walks the user through a small state machine
/// (`PreSpendInterventionStep`: input → decision → wait-confirmed / pot-created)
/// and holds all the form and evaluation state the SwiftUI view binds to. It
/// validates the input, nudges the user to set a budget first when the category
/// has none, asks the `PreSpendInterventionUseCase` to generate a reflection
/// (the on-device LLM feature for Sprint 3), and then records whichever choice
/// the user makes — Buy now, Wait, Add to a savings pot, or Skip — by calling
/// the relevant repositories and scheduling a wait reminder. It also handles
/// "re-decision" mode, where the flow is re-opened from a wait notification and
/// must resolve the original pending wait log instead of writing duplicate
/// entries (so "saved by pausing" totals aren't double-counted).
///
/// **Why it exists** — it keeps the SwiftUI view thin and declarative: the view
/// renders whatever `step` is current and forwards taps, while all the
/// orchestration, validation, persistence and side effects live here. By
/// depending only on protocols (`GoalRepository`, `BudgetRepository`,
/// `TransactionRepository`, `InterventionLogRepository`) and a use case rather
/// than concrete services, it stays unit-testable and isolates the intervention
/// feature from the rest of the app. It is `@MainActor @Observable` because it
/// drives UI directly, and uses callbacks (`onPotsChanged`, `onDismissRequested`,
/// etc.) so the parent screen — not this flow — owns navigation and refresh.
@MainActor
@Observable
final class PreSpendInterventionFlow: Identifiable {
    @ObservationIgnored let id = UUID()
    @ObservationIgnored private let useCase: PreSpendInterventionUseCase
    @ObservationIgnored private let goalRepository: any GoalRepository
    @ObservationIgnored private let budgetRepository: any BudgetRepository
    @ObservationIgnored private let transactionRepository: any TransactionRepository
    @ObservationIgnored private let interventionLogRepository: any InterventionLogRepository
    @ObservationIgnored private let waitReminderScheduler: WaitReminderScheduler
    @ObservationIgnored private let onDismissRequested: () -> Void
    @ObservationIgnored private let onPotsChanged: () -> Void
    @ObservationIgnored private let onTransactionsChanged: () -> Void
    @ObservationIgnored private let onShowCoachRequested: () -> Void

    /// When set, this flow was opened by tapping a wait notification — we
    /// should resolve the existing pending wait log on re-decision instead of
    /// writing fresh InterventionLog entries.
    @ObservationIgnored private let originalProposalID: UUID?

    var step: PreSpendInterventionStep = .input

    // Input form
    var amountText: String = ""
    var itemDescription: String = ""
    var category: TransactionCategory = .bills
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
        interventionLogRepository: some InterventionLogRepository,
        waitReminderScheduler: WaitReminderScheduler = WaitReminderScheduler(),
        currencyCode: String = "GBP",
        prefilledProposal: InterventionProposal? = nil,
        onPotsChanged: @escaping () -> Void = {},
        onTransactionsChanged: @escaping () -> Void = {},
        onShowCoachRequested: @escaping () -> Void = {},
        onDismissRequested: @escaping () -> Void
    ) {
        self.useCase = useCase
        self.goalRepository = goalRepository
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
        self.interventionLogRepository = interventionLogRepository
        self.waitReminderScheduler = waitReminderScheduler
        self.currencyCode = currencyCode
        self.onPotsChanged = onPotsChanged
        self.onTransactionsChanged = onTransactionsChanged
        self.onShowCoachRequested = onShowCoachRequested
        self.onDismissRequested = onDismissRequested

        if let proposal = prefilledProposal {
            self.amountText = Self.formatAmount(proposal.amount)
            self.itemDescription = proposal.itemDescription
            self.category = proposal.category
            self.currencyCode = proposal.currencyCode
            self.originalProposalID = proposal.id
        } else {
            self.originalProposalID = nil
        }
    }

    /// Whether this flow was opened from a wait reminder. Drives whether
    /// re-decisions resolve the existing pending wait log instead of creating
    /// a fresh one.
    var isRedecision: Bool { originalProposalID != nil }

    /// Called once when the flow first appears. If we're in re-decision mode,
    /// jump straight past the input step and run evaluation against the
    /// pre-filled proposal.
    func start() async {
        guard isRedecision, decision == nil, !isEvaluating else { return }
        await runEvaluation()
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
        // On re-decision keep the original proposal ID so any existing
        // pending wait log can be resolved against the same record.
        let id = originalProposalID ?? UUID()
        return InterventionProposal(
            id: id,
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
    /// so the user's spending records reflect what they did. On re-decision
    /// from a wait reminder, resolve the existing pending wait as `.purchased`
    /// instead of writing a duplicate log entry.
    func chooseBuyNow() async {
        guard let decision else { return }
        isRecording = true
        defer { isRecording = false }

        if isRedecision {
            await resolvePendingWait(for: decision.proposal.id, outcome: .purchased)
        } else {
            try? await useCase.recordDecision(for: decision, action: .buyNow)
        }
        await persistBuyNowTransaction(for: decision)
        onTransactionsChanged()
        onDismissRequested()
    }

    /// On a re-decision, the original wait log is still pending — we just
    /// reschedule the notification rather than logging a fresh wait, so the
    /// "saved by pausing" total isn't double-counted if the user keeps
    /// snoozing the same item.
    func chooseWait(_ duration: InterventionWaitDuration) async {
        guard let decision else { return }
        isRecording = true
        defer { isRecording = false }

        if !isRedecision {
            try? await useCase.recordDecision(for: decision, action: .wait(duration))
        }
        await waitReminderScheduler.schedule(
            for: decision.proposal,
            duration: duration
        )
        step = .waitConfirmed(duration)
    }

    /// On re-decision the existing pending wait resolves as `.skipped` (the
    /// user definitively didn't buy, so the amount counts as a save) and the
    /// new pot is created without writing an addToPot log.
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
            if isRedecision {
                await resolvePendingWait(for: decision.proposal.id, outcome: .skipped)
            } else {
                try? await useCase.recordDecision(for: decision, action: .addToPot(goalID: goal.id))
            }
            onPotsChanged()
            step = .potCreated(goal)
        } catch {
            evaluationErrorMessage = "Couldn't create the pot. Try again."
        }
    }

    /// Skip — the user definitively isn't buying this and isn't saving for it
    /// either. Only meaningful on a re-decision (there's a pending wait to
    /// resolve); resolves that wait as `.skipped` so the amount counts toward
    /// "saved by pausing" without creating a pot or transaction.
    func chooseSkip() async {
        guard let decision, isRedecision else { return }
        isRecording = true
        defer { isRecording = false }

        await resolvePendingWait(for: decision.proposal.id, outcome: .skipped)
        onDismissRequested()
    }

    func dismiss() {
        onDismissRequested()
    }

    func dismissAndShowCoach() {
        onShowCoachRequested()
        onDismissRequested()
    }

    // MARK: - Helpers

    private func resolvePendingWait(for proposalID: UUID, outcome: WaitOutcome) async {
        let pending = await interventionLogRepository.fetchPendingWaits()
        guard let log = pending.first(where: { $0.proposalID == proposalID }) else { return }
        try? await interventionLogRepository.resolveWait(id: log.id, outcome: outcome)
    }

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

    private static func formatAmount(_ amount: Double) -> String {
        if amount.rounded() == amount {
            return String(Int(amount))
        }
        return String(format: "%.2f", amount)
    }
}
