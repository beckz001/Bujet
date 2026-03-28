//
//  RootView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI

struct RootView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        TabView(selection: $appModel.selectedTab) {
            NavigationStack {
                HomeView(
                    viewModel: appModel.homeViewModel,
                    onImportSuccess: {
                        appModel.selectedTab = .transactions
                    }
                )
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(AppTab.home)
            
            NavigationStack {
                Text("Insights")
            }
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(AppTab.insights)

            NavigationStack {
                TransactionsView(viewModel: appModel.transactionsViewModel)
            }
            .tabItem {
                Label("Transactions", systemImage: "pencil.and.list.clipboard")
            }
            .tag(AppTab.transactions)

            NavigationStack {
                Text("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(AppTab.settings)
        }
    }
}
