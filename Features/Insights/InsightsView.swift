import SwiftUI

struct InsightsView: View {
    let viewModel: InsightsViewModel

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
                            percentage: viewModel.percentage(for: category)
                        )
                    }
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories this month")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.black)
                    
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
        .background(Color(hex: "EFEFD0").ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Insights")
                    .font(.custom("InstrumentSerif-Italic", size: 34))
                    .foregroundStyle(.black)
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
    }
}
