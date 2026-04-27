//
//  RootView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI

struct MainTabView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        TabView(selection: $appModel.selectedTab) {
            NavigationStack {
                HomeView(
                    viewModel: appModel.homeViewModel,
                    onImportSuccess: {
                        Task {
                            await appModel.transactionsViewModel.refresh()
                            await appModel.insightsViewModel.refresh()
                            await appModel.homeViewModel.refresh()
                        }
                        appModel.selectedTab = .transactions
                    },
                    onSeeAllTapped: {
                        appModel.selectedTab = .transactions
                    }
                )
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(TabModel.home)

            NavigationStack {
                InsightsView(viewModel: appModel.insightsViewModel)
            }
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(TabModel.insights)

            NavigationStack {
                TransactionsView(viewModel: appModel.transactionsViewModel)
            }
            .tabItem {
                Label("Transactions", systemImage: "pencil.and.list.clipboard")
            }
            .tag(TabModel.transactions)

            NavigationStack {
                Text("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(TabModel.settings)
        }
    }
}

