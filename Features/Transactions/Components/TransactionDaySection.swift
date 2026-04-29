import SwiftUI

struct TransactionDaySection: View {
    let day: Date
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Self.dayLabel(for: day))
                .font(.system(.title3, design: .serif))
                .foregroundStyle(.primary)

            VStack(spacing: 0) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                    TransactionCompactRow(transaction: transaction)
                        .padding(.horizontal, 20)
                    if index < transactions.count - 1 {
                        Divider()
                            .opacity(0.4)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surfaceTile()
        }
    }

    /// "25th April"-style label with locale-aware ordinal day suffix.
    private static func dayLabel(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        let dayString = ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let monthString = monthFormatter.string(from: date)

        return "\(dayString) \(monthString)"
    }
}
