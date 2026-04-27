import SwiftUI

struct TodaySpentTile: View {
    let amount: Double
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.system(.title, design: .serif))
                .foregroundStyle(.primary)
            
            RaisedDecimalAmount(
                amount: amount,
                currencyCode: currencyCode,
                integerSize: 32
            )
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .center)
        .padding(20)
        .surfaceTile()
    }
}
