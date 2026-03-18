//
//  RootView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI
import Observation

struct RootView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        TabView(selection: $appModel.selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack {
                    HomeView(appModel: appModel)
                }
            }

            Tab("Transactions", systemImage: "list.bullet.rectangle", value: .transactions) {
                NavigationStack {
                    TransactionsView(appModel: appModel)
                }
            }
        }
        .task {
            await appModel.loadTransactions()
        }
        .alert("Import Status", isPresented: alertIsPresented) { } message: {
            Text(appModel.alertMessage ?? "Unknown message.")
        }
    }

    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { appModel.alertMessage != nil },
            set: { newValue in
                if !newValue {
                    appModel.alertMessage = nil
                }
            }
        )
    }
}
