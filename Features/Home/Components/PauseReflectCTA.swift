import SwiftUI

/// Full-width call-to-action sitting above the today/quick-add row on Home.
/// Opens the Pause & Reflect sheet — the headline coaching moment of the app.
struct PauseReflectCTA: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "hand.raised.fill")
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.2), in: Circle())
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("I'm about to spend")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Pause & reflect before you buy")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(hex: "EC4899"), Color(hex: "7E5BEF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}
