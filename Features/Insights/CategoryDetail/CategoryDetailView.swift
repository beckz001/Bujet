import SwiftUI

struct CategoryDetailView: View {
    let viewModel: CategoryDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Total spend: \(viewModel.totalSpend.formatted(.currency(code: viewModel.currencyCode)))")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(.primary)
                    .padding(.top, 4)

                if viewModel.groupedByDay.isEmpty {
                    ContentUnavailableView(
                        "No transactions",
                        systemImage: "tray",
                        description: Text("Nothing in this category for the selected month.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(viewModel.groupedByDay) { group in
                        DayGroupSection(
                            group: group,
                            currencyCode: viewModel.currencyCode
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color(hex: "EFEFD0").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.category.displayName)
                    .font(.custom("InstrumentSerif-Italic", size: 28))
                    .italic()
                    .foregroundStyle(.primary)
            }
        }
    }
}

private struct DayGroupSection: View {
    let group: CategoryDetailViewModel.DayGroup
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.day, format: .dateTime.day().month(.wide))
                .font(.system(size: 18, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                ForEach(group.transactions) { transaction in
                    TransactionGlassRow(
                        transaction: transaction,
                        currencyCode: currencyCode
                    )
                }
            }
        }
    }
}

private struct TransactionGlassRow: View {
    let transaction: Transaction
    let currencyCode: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchantName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(transaction.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(abs(transaction.amount), format: .currency(code: currencyCode))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
