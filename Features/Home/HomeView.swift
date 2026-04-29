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
    let onSeeAllTapped: () -> Void

    #if DEBUG
    @State private var showingClearImportedAlert = false
    @State private var showingClearManualAlert = false
    #endif

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SpentThisMonthCard(
                    total: viewModel.totalAmountMonth(),
                    currencyCode: viewModel.currencyCode,
                    trend: viewModel.compareLastMonth(),
                    previousMonthLabel: viewModel.previousMonthLabel,
                    daysRemaining: viewModel.daysRemainingMonth(),
                    monthProgress: viewModel.monthProgress
                )

                HStack(spacing: 16) {
                    TodaySpentTile(
                        amount: viewModel.todaySpent(),
                        currencyCode: viewModel.currencyCode
                    )

                    QuickAddTile(action: quickAddTransaction)
                }

                HomeConnectionPill(
                    state: viewModel.bannerState,
                    onTap: connectBankAccount
                )

                RecentTransactionsCard(
                    transactions: viewModel.recentTransactions(),
                    onSeeAll: onSeeAllTapped
                )

                #if DEBUG
                debugButtons
                #endif
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppPalette.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Home")
                    .font(.custom("InstrumentSerif-Italic", size: 34))
            }
        }
        .task { await viewModel.loadTransactions() }
        .refreshable { await viewModel.refresh() }
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
            ManualTransactionSheet(flow: flow)
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

    #if DEBUG
    @ViewBuilder
    private var debugButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Clear Imported Transactions", systemImage: "trash", role: .destructive) {
                showingClearImportedAlert = true
            }
            .disabled(viewModel.isImporting)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surfaceTile()
            .alert("Clear Imported Transactions?", isPresented: $showingClearImportedAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    Task { await viewModel.clearImported() }
                }
            } message: {
                Text("This action cannot be undone.")
            }

            Button("Clear Manual Transactions", systemImage: "trash", role: .destructive) {
                showingClearManualAlert = true
            }
            .disabled(viewModel.isImporting)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surfaceTile()
            .alert("Clear Manual Transactions?", isPresented: $showingClearManualAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    Task { await viewModel.clearManual() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    #endif
}
