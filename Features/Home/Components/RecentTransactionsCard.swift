import SwiftUI

struct RecentTransactionsCard: View {
    let transactions: [Transaction]
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(.primary)

                Spacer()

                Button("See all", action: onSeeAll)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            if transactions.isEmpty {
                Text("No recent transactions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                        HomeRecentRow(transaction: transaction)
                        if index < transactions.count - 1 {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .surfaceTile()
    }
}

private struct HomeRecentRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchantName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(transaction.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(abs(transaction.amount), format: .currency(code: transaction.currencyCode))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }
}
