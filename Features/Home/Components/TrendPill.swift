import SwiftUI

struct TrendPill: View {
    let trend: SpendTrend
    let comparisonLabel: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: arrowSymbol)
                .font(.caption2.weight(.bold))
            Text("\(percentageString)% VS \(comparisonLabel)")
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(foreground)
        .background(
            Capsule().fill(background)
        )
    }

    private var arrowSymbol: String {
        switch trend {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .flat: "minus"
        }
    }

    private var percentageString: String {
        switch trend {
        case .up(let pct), .down(let pct):
            return String(Int(pct.rounded()))
        case .flat:
            return "0"
        }
    }

    private var foreground: Color {
        switch trend {
        case .up: AppPalette.trendUpForeground
        case .down: AppPalette.trendDownForeground
        case .flat: .secondary
        }
    }

    private var background: Color {
        switch trend {
        case .up: AppPalette.trendUpBackground
        case .down: AppPalette.trendDownBackground
        case .flat: Color.secondary.opacity(0.15)
        }
    }
}
