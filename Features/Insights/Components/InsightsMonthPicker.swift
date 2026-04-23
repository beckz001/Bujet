import SwiftUI

struct InsightsMonthPicker: View {
    @Binding var selectedMonth: Date
    let availableMonths: [Date]

    var body: some View {
        Menu {
            ForEach(availableMonths, id: \.self) { month in
                Button {
                    selectedMonth = month
                } label: {
                    if Calendar.current.isDate(month, equalTo: selectedMonth, toGranularity: .month) {
                        Label(Self.label(for: month, long: true), systemImage: "checkmark")
                    } else {
                        Text(Self.label(for: month, long: true))
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(Self.label(for: selectedMonth, long: false))
                    .font(.title3.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(.primary)
        }
    }

    private static func label(for date: Date, long: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = long ? "LLLL yyyy" : "LLL"
        return formatter.string(from: date)
    }
}
