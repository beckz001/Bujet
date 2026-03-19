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

            Section("TrueLayer Code Import") {
                TextField("Paste authentication code", text: $appModel.pastedAuthCode, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.body)

                Button("Import Transactions", systemImage: "arrow.down.circle", action: importTransactions)
                    .buttonStyle(.borderedProminent)
                    .disabled(appModel.isImporting || appModel.pastedAuthCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Clear Imported Transactions", systemImage: "trash", role: .destructive, action: clearTransactions)
                    .disabled(appModel.isImporting)
            }

            ImportInstructionsCard()
        }
        .navigationTitle("Bujet")
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

