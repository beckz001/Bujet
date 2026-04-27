import SwiftUI

struct CategoryTile: View {
    let category: TransactionCategory
    let transactionCount: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.systemImage)
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(.primary)
                .frame(width: 48, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text("\(transactionCount) Transaction\(transactionCount == 1 ? "" : "s")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceTile()
    }
}
