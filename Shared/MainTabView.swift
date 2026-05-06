//
//  RootView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI

struct MainTabView: View {
    @Bindable var appModel: AppModel
    @State private var pauseReflectFlow: PreSpendInterventionFlow?

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
                    },
                    onPauseReflectTapped: {
                        pauseReflectFlow = appModel.makePreSpendInterventionFlow(
                            onPotsChanged: {
                                Task { await appModel.coachViewModel.refresh() }
                            },
                            onTransactionsChanged: {
                                Task {
                                    await appModel.homeViewModel.refresh()
                                    await appModel.transactionsViewModel.refresh()
                                    await appModel.insightsViewModel.refresh()
                                }
                            },
                            onShowCoachRequested: {
                                appModel.selectedTab = .coach
                            },
                            onDismissRequested: { pauseReflectFlow = nil }
                        )
                    }
                )
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(TabModel.home)

            NavigationStack {
                CoachView(
                    viewModel: appModel.coachViewModel,
                    makePotEditorViewModel: { onSaved in
                        appModel.makePotEditorViewModel(onSaved: onSaved)
                    },
                    makePotContributionViewModel: { goal, onContributed in
                        appModel.makePotContributionViewModel(for: goal, onContributed: onContributed)
                    },
                    onTransactionsChanged: {
                        Task {
                            await appModel.homeViewModel.refresh()
                            await appModel.transactionsViewModel.refresh()
                            await appModel.insightsViewModel.refresh()
                        }
                    }
                )
            }
            .tabItem {
                Label("Coach", systemImage: "sparkles")
            }
            .tag(TabModel.coach)

            NavigationStack {
                InsightsView(
                    viewModel: appModel.insightsViewModel,
                    makeBudgetsViewModel: { onSaved in
                        appModel.makeBudgetsViewModel(onSaved: onSaved)
                    }
                )
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
        }
        .sheet(item: $pauseReflectFlow) { flow in
            PreSpendInterventionSheet(flow: flow)
        }
    }
}
