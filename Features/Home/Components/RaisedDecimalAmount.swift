import SwiftUI

/// Currency amount rendered with the symbol and pence raised and smaller than
/// the integer part — gives the design's price-tag feel.
struct RaisedDecimalAmount: View {
    let amount: Double
    let currencyCode: String
    let integerSize: CGFloat

    private var smallSize: CGFloat { integerSize * 0.42 }
    private var raisedOffset: CGFloat { integerSize * 0.45 }

    var body: some View {
        let parts = Self.split(amount: amount, currencyCode: currencyCode)

        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(parts.symbol)
                .font(.system(size: smallSize, design: .serif))
                .baselineOffset(raisedOffset)

            Text(parts.integer)
                .font(.system(size: integerSize, design: .serif))
                .italic()

            Text(parts.separator + parts.fraction)
                .font(.system(size: smallSize, design: .serif))
                .baselineOffset(raisedOffset)
        }
        .foregroundStyle(.primary)
    }

    private struct Parts {
        let symbol: String
        let integer: String
        let separator: String
        let fraction: String
    }

    private static func split(amount: Double, currencyCode: String) -> Parts {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        let symbol = formatter.currencySymbol ?? ""
        let separator = formatter.currencyDecimalSeparator ?? "."

        let absAmount = abs(amount)
        let integerPart = Int(absAmount.rounded(.down))
        let fractionPart = Int(((absAmount - Double(integerPart)) * 100).rounded())

        let integerFormatter = NumberFormatter()
        integerFormatter.numberStyle = .decimal
        integerFormatter.groupingSeparator = formatter.currencyGroupingSeparator
        let integerString = integerFormatter.string(from: NSNumber(value: integerPart)) ?? "\(integerPart)"

        return Parts(
            symbol: symbol,
            integer: integerString,
            separator: separator,
            fraction: String(format: "%02d", fractionPart)
        )
    }
}
