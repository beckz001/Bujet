import SwiftUI
import Observation

struct TransactionsView: View {
    let viewModel: TransactionsViewModel

    var body: some View {
        @Bindable var bindableViewModel = viewModel
        Group {
            if viewModel.filteredTransactions.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "tray",
                    description: Text(emptyDescription)
                )
            } else {
                List(viewModel.filteredTransactions) { transaction in
                    TransactionRowView(transaction: transaction)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Transactions")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        Button {
                            bindableViewModel.filter = filter
                        } label: {
                            if bindableViewModel.filter == filter {
                                Label(filter.rawValue, systemImage: "checkmark")
                            } else {
                                Text(filter.rawValue)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .accessibilityLabel("Filter transactions")
            }
        }
        .task {
            await viewModel.loadTransactions()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var emptyTitle: String {
        switch viewModel.filter {
        case .all: return "No Transactions"
        case .imported: return "No Imported Transactions"
        case .manual: return "No Manual Transactions"
        }
    }

    private var emptyDescription: String {
        switch viewModel.filter {
        case .all: return "Import transactions from the Home tab to see them here."
        case .imported: return "Connect to a bank account from the Home tab to import transactions."
        case .manual: return "Add manual transactions from the Home tab."
        }
    }
}
