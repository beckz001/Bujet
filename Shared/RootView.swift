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
            
            Tab("Insights", systemImage: "chart.line.uptrend.xyaxis", value: .insights) {
                NavigationStack {
                    EmptyView()
                }
            }

            Tab("Transactions", systemImage: "pencil.and.list.clipboard", value: .transactions) {
                NavigationStack {
                    TransactionsView(appModel: appModel)
                }
            }
            
            Tab("Settings", systemImage: "slider.horizontal.3", value: .settings) {
                NavigationStack {
                    EmptyView()
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
