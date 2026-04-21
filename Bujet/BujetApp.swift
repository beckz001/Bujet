//
//  BujetApp.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import SwiftUI

@main
struct BujetApp: App {
    @State private var appModel = AppModel(
        transactionRepository: LocalTransactionRepository(),
        authClient: BackendAuthClient(baseURL: BackendConfiguration.baseURL)
    )

    var body: some Scene {
        WindowGroup {
            MainTabView(appModel: appModel)
        }
    }
}
