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

    private let notificationDelegate = NotificationCenterDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(appModel: appModel)
        }
    }
}
