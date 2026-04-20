//
//  HomeView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI
import Observation

struct HomeView: View {
    let viewModel: HomeViewModel
    let onImportSuccess: () -> Void

    @State private var showingClearAlert = false

    var body: some View {
        @Bindable var bindableViewModel = viewModel
        let bannerState = viewModel.bannerState

        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    HomeConnectionBar(
                        state: bannerState
                    )

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
                            isDisabled: viewModel.isImporting || viewModel.bannerState == .connected
                        )
                    }

                    HomeGlassCard(minHeight: 180) {
                        VStack {
                            Text("Example of a large content card")
                        }
                    }

                    HomeGlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Button("Clear Imported Transactions", systemImage: "trash", role: .destructive) {
                                showingClearAlert = true
                            }
                            .disabled(viewModel.isImporting)
                            .alert("Clear Imported Transactions?", isPresented: $showingClearAlert) {
                                Button("Cancel", role: .cancel) { }
                                Button("Clear", role: .destructive, action: clearTransactions)
                            } message: {
                                Text("This action cannot be undone.")
                            }
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
        }
        .navigationTitle("Home")
        .alert(item: $bindableViewModel.connectionAlert) { alert in
            switch alert {
            case .serverConnection(let message):
                return Alert(
                    title: Text("Connection Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )

            case .connectionCancelled:
                return Alert(
                    title: Text("Connection Cancelled"),
                    message: Text("Bank connection cancelled, no data was sent to the server."),
                    dismissButton: .default(Text("OK")) {
                        viewModel.clearErrorAlert()
                    }
                )

            case .dataAPIError(let title, let message):
                return Alert(
                    title: Text(title),
                    message: Text(message),
                    dismissButton: .default(Text("OK")) {
                        viewModel.clearErrorAlert()
                    }
                )
            }
        }
        .sheet(
            item: $bindableViewModel.presentedImportSheet,
            onDismiss: {
                viewModel.handleImportSheetDismissal()
            }
        ) { step in
            if let flow = viewModel.activeImportFlow {
                switch step {
                case .options:
                    TransactionImportOptionsSheet(
                        viewModel: ImportOptionsViewModel(flow: flow)
                    )
                case .review:
                    TransactionImportReviewSheet(
                        viewModel: ImportReviewViewModel(flow: flow)
                    )
                }
            }
        }
        .sheet(item: $bindableViewModel.activeManualFlow) { flow in
            ManualTransactionSheet(
                viewModel: ManualTransactionViewModel(flow: flow)
            )
        }
        .alert(item: $bindableViewModel.manualImportResult) { result in
            Alert(
                title: Text("Import Successful"),
                message: Text("\(result.count) transaction(s) added."),
                primaryButton: .default(Text("View Transactions")) {
                    onImportSuccess()
                },
                secondaryButton: .cancel(Text("OK"))
            )
        }
    }

    private func quickAddTransaction() {
        viewModel.startManualImport()
    }

    private func connectBankAccount() {
        Task {
            await viewModel.startBankConnection(onImportSuccess: onImportSuccess)
        }
    }

    private func clearTransactions() {
        Task {
            await viewModel.clearTransactions()
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

// MARK: - Connection bar
private struct HomeConnectionBar: View {
    let state: ConnectionBannerState

    private var title: String {
        switch state {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .dataPending:
            return "Connecting"
        case .importFailed:
            return "Disconnected"
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
            Image(systemName: "network.slash")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: Action Card
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

// MARK: Glass Card
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
