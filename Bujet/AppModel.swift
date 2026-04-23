import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    @ObservationIgnored
    private let connectionStore: BankConnectionStateStore

    var selectedTab: TabModel = .home

    let homeViewModel: HomeViewModel
    let transactionsViewModel: TransactionsViewModel
    let insightsViewModel: InsightsViewModel

    init(
        transactionRepository: some TransactionRepository,
        authClient: BackendAuthClient,
        defaults: UserDefaults = .standard
    ) {
        let connectionStore = BankConnectionStateStore(defaults: defaults)
        let connector = BankAccountConnector(authClient: authClient)
        self.connectionStore = connectionStore

        self.homeViewModel = HomeViewModel(
            transactionRepository: transactionRepository,
            connector: connector,
            connectionStore: connectionStore
        )

        self.transactionsViewModel = TransactionsViewModel(
            transactionRepository: transactionRepository
        )

        self.insightsViewModel = InsightsViewModel(
            transactionRepository: transactionRepository
        )
    }
}
