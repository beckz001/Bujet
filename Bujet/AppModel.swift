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
    }
}

extension String {
    /// Alphanumeric + spaces only
    var alphanumericWithSpacesOnly: String {
        self.filter { $0.isLetter || $0.isNumber || $0 == " " }
    }

    /// Banking-style amount sanitiser (numbers + one decimal, 2 dp)
    var sanitisedAmount: String {
        var result = ""
        var hasDecimal = false
        var decimalCount = 0

        for char in self {
            if char.isNumber {
                if hasDecimal {
                    guard decimalCount < 2 else { continue }
                    decimalCount += 1
                }
                result.append(char)
            } else if char == "." && !hasDecimal {
                hasDecimal = true
                result.append(char)
            }
        }

        return result
    }
}
