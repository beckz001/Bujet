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

    init(
        transactionRepository: some TransactionRepository,
        authClient: BackendAuthClient,
        defaults: UserDefaults = .standard
    ) {
        let connectionStore = BankConnectionStateStore(defaults: defaults)
        self.connectionStore = connectionStore

        self.homeViewModel = HomeViewModel(
            transactionRepository: transactionRepository,
            authClient: authClient,
            connectionStore: connectionStore
        )

        self.transactionsViewModel = TransactionsViewModel(
            transactionRepository: transactionRepository
        )
    }
}
