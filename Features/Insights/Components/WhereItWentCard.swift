import SwiftUI

struct WhereItWentCard: View {
    let total: Double
    let currencyCode: String
    let rows: [Row]

    struct Row: Identifiable {
        let category: TransactionCategory
        let amount: Double
        /// The user's budget limit for this category, if set. When `nil` the
        /// row falls back to "no budget" treatment.
        let budgetLimit: Double?

        var id: TransactionCategory { category }

        /// Percent of budget used. `nil` when no budget is set.
        var percentageOfBudget: Double? {
            guard let limit = budgetLimit, limit > 0 else { return nil }
            return amount / limit * 100
        }

        var isOverBudget: Bool {
            (percentageOfBudget ?? 0) > 100
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where it went")
                .font(.system(.body, design: .serif))
                .foregroundStyle(.foreground)

            Text(total, format: .currency(code: currencyCode))
                .font(.system(size: 40, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(.primary)

            VStack(spacing: 10) {
                ForEach(rows) { row in
                    CategoryRow(
                        row: row,
                        currencyCode: currencyCode
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .surfaceTile()
    }
}

private struct CategoryRow: View {
    let row: WhereItWentCard.Row
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(row.category.color)
                    .frame(width: 8, height: 8)

                Text(row.category.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)

                if row.isOverBudget {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Over budget")
                }

                Spacer(minLength: 8)

                Text(row.amount, format: .currency(code: currencyCode))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.secondary)

                budgetPercentLabel
            }

            PercentageBar(
                percentageOfBudget: row.percentageOfBudget,
                color: row.isOverBudget ? .red : row.category.color
            )
        }
    }

    @ViewBuilder
    private var budgetPercentLabel: some View {
        if let percent = row.percentageOfBudget {
            Text("\(Int(percent.rounded()))% of budget")
                .font(.footnote)
                .foregroundStyle(row.isOverBudget ? .red : .secondary)
                .monospacedDigit()
        } else {
            Text("No budget")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PercentageBar: View {
    /// Percent of budget used. `nil` means no budget is set — the bar shows an
    /// empty track.
    let percentageOfBudget: Double?
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))

                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * clampedFraction)
            }
        }
        .frame(height: 5)
    }

    private var clampedFraction: CGFloat {
        guard let percent = percentageOfBudget else { return 0 }
        return CGFloat(max(0, min(100, percent)) / 100)
    }
}
