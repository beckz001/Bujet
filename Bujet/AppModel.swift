import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    @ObservationIgnored
    private let connectionStore: ConnectionStateStore

    var selectedTab: AppTab = .home

    let homeViewModel: HomeViewModel
    let transactionsViewModel: TransactionsViewModel

    init(
        transactionRepository: some TransactionRepository,
        authClient: BackendAuthClient,
        defaults: UserDefaults = .standard
    ) {
        let connectionStore = ConnectionStateStore(defaults: defaults)
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
