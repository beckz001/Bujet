//
//  HomeView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI
import Observation

struct HomeView: View {
    @Bindable var appModel: AppModel
    @State private var showingClearAlert = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
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

                HomeGlassCard(minHeight: 180) {
                    VStack(alignment: .leading, spacing: 16) {
                        ConnectionStatusCard(connectionState: appModel.connectionState)

                        Button("Import Transactions", systemImage: "arrow.down.circle", action: connectBankAccount)
                            .buttonStyle(.glassProminent)
                            .disabled(appModel.isImporting)

                        if appModel.isImporting {
                            ProgressView("Connecting and importing…")
                        }

                        Text("Starts the TrueLayer login flow, exchanges the code in the backend, and imports transactions automatically.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

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
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background {
            HomeBackground()
        }
        .navigationTitle("Home")
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

private struct HomeActionCard: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var isDisabled = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 18) {
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .light))

                Text(title)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .padding(20)
            .foregroundStyle(.primary)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(.white.opacity(0.55), lineWidth: 1)
            }
            .shadow(color: .purple.opacity(0.14), radius: 18, y: 8)
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
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 30))
    }
}

