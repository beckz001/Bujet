import SwiftUI

struct WaitConfirmedView: View {
    let duration: InterventionWaitDuration
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Sleeping on it")
                    .font(.title2.weight(.semibold))
                Text(messageText)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                onDone()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var messageText: String {
        switch duration {
        case .oneDay:
            "We'll nudge you in 24 hours. If you still want it then, go ahead — and if not, that's a win you can see in your saved-by-pausing total."
        case .sevenDays:
            "We'll check in after a week. Many impulses fade fast — if it still matters in 7 days, it probably matters."
        case .endOfMonth:
            "We'll come back at the end of the month. Plenty of time to see if this purchase still makes the cut."
        }
    }
}
