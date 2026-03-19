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

    var body: some View {
        Form {
            ConnectionStatusCard(connectionState: appModel.connectionState)

            Section("Import Transactions") {
                Button("Import Transactions", systemImage: "arrow.down.circle", action: connectBankAccount)
                    .buttonStyle(.borderedProminent)
                    .disabled(appModel.isImporting)

                if appModel.isImporting {
                    ProgressView("Connecting and importing…")
                }

                Text("Starts the TrueLayer login flow, exchanges the code in the backend, and imports transactions automatically.")
                    .foregroundStyle(.secondary)
            }

            Section("Manual Fallback (Debug Only)") {
                TextField("Paste authentication code", text: $appModel.pastedAuthCode, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Import Transactions Manually", systemImage: "arrow.down.circle", action: importTransactions)
                    .disabled(appModel.isImporting || appModel.pastedAuthCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Button("Clear Imported Transactions", systemImage: "trash", role: .destructive, action: clearTransactions)
                .disabled(appModel.isImporting)

            ImportInstructionsCard()
        }
        .navigationTitle("Bujet")
    }

    private func connectBankAccount() {
        Task {
            await appModel.startTrueLayerFlow()
        }
    }

    private func importTransactions() {
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
