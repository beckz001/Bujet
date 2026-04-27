import SwiftUI

struct SpentThisMonthCard: View {
    let total: Double
    let currencyCode: String
    let trend: SpendTrend
    let previousMonthLabel: String
    let daysRemaining: Int
    let monthProgress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("Spent this month")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                TrendPill(trend: trend, comparisonLabel: previousMonthLabel)
            }

            RaisedDecimalAmount(
                amount: total,
                currencyCode: currencyCode,
                integerSize: 44
            )

            Text("\(daysRemaining) days remaining")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.top, 4)

            MonthProgressBar(progress: monthProgress)
                .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .surfaceTile()
    }
}

private struct MonthProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(AppPalette.progressTrack)
                Capsule()
                    .fill(AppPalette.progressFill)
                    .frame(width: geometry.size.width * clamped)
            }
        }
    }

    private var clamped: CGFloat {
        CGFloat(max(0, min(1, progress)))
    }
}
