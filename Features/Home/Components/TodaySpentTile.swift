import SwiftUI

struct TodaySpentTile: View {
    let amount: Double
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            RaisedDecimalAmount(
                amount: amount,
                currencyCode: currencyCode,
                integerSize: 32
            )
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .padding(20)
        .surfaceTile()
    }
}
