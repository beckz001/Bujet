//
//  HomeView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI
import Observation

private enum HomeBannerState {
    case connected
    case disconnected
    case dataPending
    case importFailed
}

struct HomeView: View {
    @Bindable var appModel: AppModel
    @State private var showingClearAlert = false
    @State private var showingRetryPopup = false

    private var bannerState: HomeBannerState {
        if appModel.isImporting {
            return .dataPending
        }

        // TODO:
        // When you have a dedicated failure flag in AppModel, uncomment / adapt this.
        // Example:
        // if appModel.didImportFailAfterConnection {
        //     return .importFailed
        // }

        switch appModel.connectionState {
        case .connected:
            return .connected
        default:
            return .disconnected
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {

                    // MARK: Connection bar
                    HomeConnectionBar(
                        state: bannerState,
                        action: handleConnectionBarTap
                    )

                    // MARK: - Action cards
                    HStack(spacing: 16) {
                        HomeActionCard(
                            title: "Quick add\ntransaction",
                            systemImage: "plus",
                            action: quickAddTransaction
                        )

                        HomeActionCard(
                            title: "Connect to a\nbank account",
                            systemImage: "building.columns",
                            action: connectBankAccount,
                            isDisabled: appModel.isImporting
                        )
                    }

                    // MARK: - Large content card (blank)
                    HomeGlassCard(minHeight: 180) {
                        VStack {
                            Text("Example of a large content card")
                        }
                    }

                    // MARK: - Existing manual fallback card
                    HomeGlassCard(minHeight: 240) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Manual fallback")
                                .font(.headline)
                                .bold()

                            TextField("Paste authentication code", text: $appModel.pastedAuthCode, axis: .vertical)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(.white.opacity(0.55), in: .rect(cornerRadius: 18))

                            Button("Import Transactions Manually", systemImage: "arrow.down.circle", action: importTransactionsManually)
                                .disabled(
                                    appModel.isImporting ||
                                    appModel.pastedAuthCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                )

                            Button("Clear Imported Transactions", systemImage: "trash", role: .destructive) {
                                showingClearAlert = true
                            }
                            .disabled(appModel.isImporting)
                            .alert("Clear Imported Transactions?", isPresented: $showingClearAlert) {
                                Button("Cancel", role: .cancel) { }
                                Button("Clear", role: .destructive, action: clearTransactions)
                            } message: {
                                Text("This action cannot be undone.")
                            }

                            ImportInstructionsCard()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background {
                HomeBackground()
            }

            if showingRetryPopup {
                RetryImportOverlay(
                    onCancel: { showingRetryPopup = false },
                    onRetry: {
                        showingRetryPopup = false
                        connectBankAccount()
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .navigationTitle("Home")
    }

    // MARK: - Banner tap handling
    private func handleConnectionBarTap() {
        switch bannerState {
        case .connected:
            break

        case .disconnected:
            connectBankAccount()

        case .dataPending:
            break

        case .importFailed:
            showingRetryPopup = true
        }
    }

    private func quickAddTransaction() {
        // Hook this up to your add-transaction flow when ready.
    }

    private func connectBankAccount() {
        Task {
            await appModel.startTrueLayerFlow()
        }
    }

    private func importTransactionsManually() {
        Task {
            await appModel.importTransactionsFromPastedCode()
        }
    }

    private func clearTransactions() {
        Task {
            await appModel.clearTransactions()
        }
    }
}

private struct HomeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color.purple.opacity(0.14),
                    Color.purple.opacity(0.32)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color.purple.opacity(0.22),
                    .clear
                ],
                center: .bottom,
                startRadius: 80,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Top connection bar
private struct HomeConnectionBar: View {
    let state: HomeBannerState
    let action: () -> Void

    private var title: String {
        switch state {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .dataPending:
            return "Connecting"
        case .importFailed:
            return "Connected"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding()

            Spacer(minLength: 8)

            trailingIcon
                .padding()
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 45)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
    }

    @ViewBuilder
    private var trailingIcon: some View {
        switch state {
        case .connected:
            Image(systemName: "network")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(.primary)

        case .disconnected:
            Image(systemName: "network.slash")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(.primary)

        case .dataPending:
            ProgressView()
                .controlSize(.regular)
                .tint(.primary)
                .scaleEffect(0.85)

        case .importFailed:
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

private struct HomeActionCard: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var isDisabled = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 45, weight: .medium))

                Text(title)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 132)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .foregroundStyle(.primary)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

private struct HomeGlassCard<Content: View>: View {
    let minHeight: CGFloat?
    @ViewBuilder let content: Content

    init(minHeight: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .padding(20)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
    }
}

// MARK: - Retry popup
private struct RetryImportOverlay: View {
    let onCancel: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.14)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("Connected but data not imported, tap to try again")
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.black.opacity(0.08), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)

                    Button(action: onRetry) {
                        Text("Try again")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.blue, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
            }
            .padding(20)
            .frame(width: 270)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.systemGray6))
            )
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        }
    }
}
