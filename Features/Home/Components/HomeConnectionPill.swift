import SwiftUI

struct HomeConnectionPill: View {
    let state: ConnectionBannerState
    let onTap: () -> Void

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 12) {
                leadingIcon
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .surfaceTile(cornerRadius: 28)
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
    }

    private func handleTap() {
        guard isInteractive else { return }
        onTap()
    }

    private var isInteractive: Bool {
        switch state {
        case .disconnected, .importFailed: true
        case .connected, .dataPending: false
        }
    }

    private var label: String {
        switch state {
        case .connected: "Connected"
        case .dataPending: "Connecting"
        case .disconnected, .importFailed: "Disconnected · Press to connect"
        }
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch state {
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppPalette.trendDownForeground)
        case .dataPending:
            ProgressView()
                .controlSize(.small)
                .tint(.primary)
        case .disconnected, .importFailed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppPalette.trendUpForeground)
        }
    }
}
