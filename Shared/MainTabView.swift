//
//  RootView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI

struct MainTabView: View {
    @Bindable var appModel: AppModel
    let waitReminderRouter: WaitReminderRouter
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
                        pauseReflectFlow = makeFlow(prefilledProposal: nil)
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
                .task { await flow.start() }
        }
        .onChange(of: waitReminderRouter.pendingProposal) { _, proposal in
            guard let proposal else { return }
            handleWaitReminderTap(proposal: proposal)
        }
        .task {
            // Cold-start case: notification tap was handled before the view
            // wired up its onChange observer.
            if let proposal = waitReminderRouter.pendingProposal {
                handleWaitReminderTap(proposal: proposal)
            }
        }
    }

    private func makeFlow(prefilledProposal: InterventionProposal?) -> PreSpendInterventionFlow {
        appModel.makePreSpendInterventionFlow(
            prefilledProposal: prefilledProposal,
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

    /// If a sheet is already up (manual flow, or stale state) we dismiss it
    /// first and re-present on the next runloop so SwiftUI actually animates
    /// the new flow in. Otherwise present immediately.
    private func handleWaitReminderTap(proposal: InterventionProposal) {
        waitReminderRouter.pendingProposal = nil
        let newFlow = makeFlow(prefilledProposal: proposal)
        if pauseReflectFlow != nil {
            pauseReflectFlow = nil
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 50_000_000)
                pauseReflectFlow = newFlow
            }
        } else {
            pauseReflectFlow = newFlow
        }
    }
}
