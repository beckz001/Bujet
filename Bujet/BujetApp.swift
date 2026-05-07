//
//  BujetApp.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import SwiftUI
import UserNotifications

@main
struct BujetApp: App {
    @State private var appModel = AppModel(
        transactionRepository: LocalTransactionRepository(),
        budgetRepository: LocalBudgetRepository(),
        goalRepository: LocalGoalRepository(),
        interventionLogRepository: LocalInterventionLogRepository(),
        authClient: BackendAuthClient(baseURL: BackendConfiguration.baseURL)
    )

    @State private var waitReminderRouter: WaitReminderRouter

    private let notificationDelegate: NotificationCenterDelegate

    init() {
        let router = WaitReminderRouter()
        _waitReminderRouter = State(initialValue: router)
        let delegate = NotificationCenterDelegate(router: router)
        self.notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(
                appModel: appModel,
                waitReminderRouter: waitReminderRouter
            )
        }
    }
}
