import SwiftUI

struct PotCreatedView: View {
    let goal: Goal
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("Pot created")
                    .font(.title2.weight(.semibold))
                Text("'\(goal.name)' is now a pot. Add to it whenever you have a little surplus — we'll celebrate when it fills.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                onDone()
            } label: {
                Text("View in Coach")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}
