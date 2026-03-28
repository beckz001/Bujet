import SwiftUI
import Observation

struct TransactionsView: View {
    let viewModel: TransactionsViewModel

    var body: some View {
        Group {
            if viewModel.transactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "tray",
                    description: Text("Import transactions from the Home tab to see them here.")
                )
            } else {
                List(viewModel.transactions) { transaction in
                    TransactionRowView(transaction: transaction)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Transactions")
        .task {
            await viewModel.loadTransactions()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
