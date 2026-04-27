import SwiftUI

struct QuickAddTile: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, minHeight: 110)
                .padding(20)
                .surfaceTile()
        }
        .buttonStyle(.plain)
    }
}
