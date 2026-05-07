import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    @ObservationIgnored
    private let connectionStore: BankConnectionStateStore
    @ObservationIgnored
    let transactionRepository: any TransactionRepository
    @ObservationIgnored
    let budgetRepository: any BudgetRepository
    @ObservationIgnored
    let goalRepository: any GoalRepository
    @ObservationIgnored
    let interventionLogRepository: any InterventionLogRepository
    @ObservationIgnored
    let preSpendInterventionUseCase: PreSpendInterventionUseCase

    var selectedTab: TabModel = .home

    let homeViewModel: HomeViewModel
    let transactionsViewModel: TransactionsViewModel
    let insightsViewModel: InsightsViewModel
    let coachViewModel: CoachViewModel

    init(
        transactionRepository: some TransactionRepository,
        budgetRepository: some BudgetRepository,
        goalRepository: some GoalRepository,
        interventionLogRepository: some InterventionLogRepository,
        authClient: BackendAuthClient,
        defaults: UserDefaults = .standard
    ) {
        let connectionStore = BankConnectionStateStore(defaults: defaults)
        let connector = BankAccountConnector(authClient: authClient)
        self.connectionStore = connectionStore
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.goalRepository = goalRepository
        self.interventionLogRepository = interventionLogRepository

        let contextProvider = SpendingContextProvider(
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            goalRepository: goalRepository,
            interventionLogRepository: interventionLogRepository
        )
        let narrativeService = LLMServiceFactory.make()
        self.preSpendInterventionUseCase = PreSpendInterventionUseCase(
            contextProvider: contextProvider,
            narrativeService: narrativeService,
            interventionLogRepository: interventionLogRepository
        )
        let weeklyInsightsUseCase = GenerateWeeklyInsightsUseCase(
            contextProvider: contextProvider,
            analysers: [OverspendAnalyser(), RecurringSmallSpendAnalyser()],
            narrativeService: narrativeService
        )

        self.homeViewModel = HomeViewModel(
            transactionRepository: transactionRepository,
            connector: connector,
            connectionStore: connectionStore
        )

        self.transactionsViewModel = TransactionsViewModel(
            transactionRepository: transactionRepository
        )

        self.insightsViewModel = InsightsViewModel(
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        )

        self.coachViewModel = CoachViewModel(
            goalRepository: goalRepository,
            interventionLogRepository: interventionLogRepository,
            transactionRepository: transactionRepository,
            weeklyInsightsUseCase: weeklyInsightsUseCase
        )
    }

    func makeBudgetsViewModel(onSaved: @escaping () -> Void = {}) -> BudgetsViewModel {
        BudgetsViewModel(
            budgetRepository: budgetRepository,
            currencyCode: insightsViewModel.currencyCode,
            onSaved: onSaved
        )
    }

    func makePreSpendInterventionFlow(
        onPotsChanged: @escaping () -> Void = {},
        onTransactionsChanged: @escaping () -> Void = {},
        onShowCoachRequested: @escaping () -> Void = {},
        onDismissRequested: @escaping () -> Void
    ) -> PreSpendInterventionFlow {
        PreSpendInterventionFlow(
            useCase: preSpendInterventionUseCase,
            goalRepository: goalRepository,
            budgetRepository: budgetRepository,
            transactionRepository: transactionRepository,
            currencyCode: insightsViewModel.currencyCode,
            onPotsChanged: onPotsChanged,
            onTransactionsChanged: onTransactionsChanged,
            onShowCoachRequested: onShowCoachRequested,
            onDismissRequested: onDismissRequested
        )
    }

    func makePotEditorViewModel(onSaved: @escaping () -> Void = {}) -> PotEditorViewModel {
        PotEditorViewModel(
            goalRepository: goalRepository,
            currencyCode: coachViewModel.currencyCode,
            onSaved: onSaved
        )
    }

    func makePotContributionViewModel(
        for goal: Goal,
        onContributed: @escaping () -> Void = {}
    ) -> PotContributionViewModel {
        PotContributionViewModel(
            goal: goal,
            goalRepository: goalRepository,
            onContributed: onContributed
        )
    }
}
