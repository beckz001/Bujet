import SwiftUI

struct WhereItWentCard: View {
    let total: Double
    let currencyCode: String
    let rows: [Row]

    struct Row: Identifiable {
        let category: TransactionCategory
        let amount: Double
        let percentage: Double

        var id: TransactionCategory { category }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where it went")
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
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

                Spacer(minLength: 8)

                Text(row.amount, format: .currency(code: currencyCode))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.secondary)

                Text("\(Int(row.percentage.rounded()))%")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            PercentageBar(
                percentage: row.percentage,
                color: row.category.color
            )
        }
    }
}

private struct PercentageBar: View {
    let percentage: Double
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
        CGFloat(max(0, min(100, percentage)) / 100)
    }
}
