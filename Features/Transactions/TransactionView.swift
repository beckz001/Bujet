import SwiftUI
import Observation

struct TransactionsView: View {
    let viewModel: TransactionsViewModel

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                filterChips

                if viewModel.groupedByDay.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.groupedByDay) { group in
                        TransactionDaySection(
                            day: group.day,
                            transactions: group.transactions
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppPalette.background.ignoresSafeArea())
        .searchable(
            text: $bindableViewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Transactions"
        )
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Transactions")
                    .font(.custom("InstrumentSerif-Italic", size: 34))
                    .foregroundStyle(.black)
            }
        }
        .task { await viewModel.loadTransactions() }
        .refreshable { await viewModel.refresh() }
    }

    private var filterChips: some View {
        HStack(spacing: 10) {
            ForEach(TransactionFilter.allCases) { filter in
                FilterChip(
                    title: filter.rawValue,
                    isSelected: viewModel.filter == filter
                ) {
                    viewModel.filter = filter
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        let isSearching = !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        VStack(spacing: 8) {
            if isSearching {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "tray",
                    description: Text(emptyDescription)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var emptyTitle: String {
        switch viewModel.filter {
        case .all: "No Transactions"
        case .imported: "No Imported Transactions"
        case .manual: "No Manual Transactions"
        }
    }

    private var emptyDescription: String {
        switch viewModel.filter {
        case .all: "Import transactions from the Home tab to see them here."
        case .imported: "Connect to a bank account from the Home tab to import transactions."
        case .manual: "Add manual transactions from the Home tab."
        }
    }
}
