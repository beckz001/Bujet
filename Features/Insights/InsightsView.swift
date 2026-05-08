import SwiftUI

struct InsightsView: View {
    let viewModel: InsightsViewModel
    let makeBudgetsViewModel: (@escaping () -> Void) -> BudgetsViewModel

    @State private var presentedBudgetsViewModel: BudgetsViewModel?

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                WhereItWentCard(
                    total: viewModel.monthTotal,
                    currencyCode: viewModel.currencyCode,
                    rows: TransactionCategory.allCases.map { category in
                        WhereItWentCard.Row(
                            category: category,
                            amount: viewModel.total(for: category),
                            budgetLimit: viewModel.budgetLimit(for: category)
                        )
                    }
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories this month")
                        .font(.system(.subheadline, design: .serif))
                    
                    VStack(spacing: 12) {
                        ForEach(TransactionCategory.allCases) { category in
                            NavigationLink {
                                CategoryDetailView(
                                    viewModel: CategoryDetailViewModel(
                                        category: category,
                                        month: viewModel.selectedMonth,
                                        transactions: viewModel.transactions,
                                        currencyCode: viewModel.currencyCode
                                    )
                                )
                            } label: {
                                CategoryTile(
                                    category: category,
                                    transactionCount: viewModel.count(for: category)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppPalette.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Insights")
                    .font(.custom("InstrumentSerif-Italic", size: 34))
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    presentedBudgetsViewModel = makeBudgetsViewModel {
                        Task { await viewModel.reloadBudgets() }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Set budgets")
            }
            ToolbarItem(placement: .topBarTrailing) {
                InsightsMonthPicker(
                    selectedMonth: $bindableViewModel.selectedMonth,
                    availableMonths: viewModel.availableMonths
                )
            }
        }
        .task { await viewModel.loadTransactions() }
        .refreshable { await viewModel.refresh() }
        .sheet(item: $presentedBudgetsViewModel) { vm in
            BudgetsSheet(viewModel: vm)
        }
    }
}
