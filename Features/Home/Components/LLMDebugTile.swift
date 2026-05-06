#if DEBUG
import SwiftUI
import FoundationModels

/// Debug-only tile that reports `SystemLanguageModel.default.availability` so
/// we can see at a glance whether the on-device model is ready, and *why* not
/// if it isn't.
struct LLMDebugTile: View {
    @State private var statusText: String = "Tap to check"
    @State private var statusColor: Color = .secondary

    var body: some View {
        Button {
            refresh()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("On-device LLM", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(statusColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surfaceTile(cornerRadius: 16)
        }
        .buttonStyle(.plain)
        .task { refresh() }
    }

    private func refresh() {
        let availability = SystemLanguageModel.default.availability
        statusText = describe(availability)
        if case .available = availability {
            statusColor = .green
        } else {
            statusColor = .orange
        }
    }

    private func describe(_ availability: SystemLanguageModel.Availability) -> String {
        // Reflection-style introspection so we don't have to keep this in
        // sync with every potential UnavailableReason case Apple ships.
        let mirrored = String(describing: availability)
        switch availability {
        case .available:
            return "Available — Foundation Models will be used. (\(mirrored))"
        default:
            return """
            Not available — using the template fallback.

            Raw value: \(mirrored)

            Common fixes:
            • macOS: System Settings → Apple Intelligence & Siri — wait until the model finishes downloading (can take a while; check the spinner).
            • Restart the simulator after Apple Intelligence is enabled.
            • Make sure the simulator runs an iOS 26 device profile.
            """
        }
    }
}
#endif
