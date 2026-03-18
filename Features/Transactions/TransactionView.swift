//
//  TransactionView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI
import Observation

struct TransactionsView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        Group {
            if appModel.transactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "tray",
                    description: Text("Import transactions from the Home tab to see them here.")
                )
            } else {
                List(appModel.transactions) { transaction in
                    TransactionRowView(transaction: transaction)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Transactions")
        .task {
            await appModel.loadTransactions()
        }
        .refreshable {
            await appModel.loadTransactions()
        }
    }
}
