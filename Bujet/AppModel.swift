//
//  AppModel.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let transactionRepository: any TransactionRepository
    private let authClient: BackendAuthClient
    private let authService = TrueLayerAuthService()
    
    @ObservationIgnored
    private let defaults: UserDefaults
    
    @ObservationIgnored
    private let connectionStateKey = "app.connectionState"

    var selectedTab: AppTab = .home
    var connectionState: BankConnectionState = .notConnected {
        didSet {
            persistConnectionState()
        }
    }
    var pastedAuthCode = ""
    var transactions: [Transaction] = []
    var isImporting = false
    var alertMessage: String?

    init(
        transactionRepository: some TransactionRepository,
        authClient: BackendAuthClient,
        defaults: UserDefaults = .standard
    ) {
        self.transactionRepository = transactionRepository
        self.authClient = authClient
        self.defaults = defaults
        
        self.connectionState = Self.loadPersistedConnectionState(from: defaults)
    }

    func loadTransactions() async {
        transactions = await transactionRepository.fetchAll()
    }

    func startTrueLayerFlow() async {
        isImporting = true
        connectionState = .importing

        do {
            let startResponse = try await authClient.startAuth()

            authService.start(authURL: startResponse.authURL) { [weak self] result in
                guard let self else { return }

                Task {
                    defer {
                        self.isImporting = false
                    }

                    do {
                        let callbackURL = try result.get()

                        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                              let sessionID = components.queryItems?.first(where: { $0.name == "session_id" })?.value,
                              let status = components.queryItems?.first(where: { $0.name == "status" })?.value else {
                            throw AuthFlowError.invalidCallback
                        }

                        if status == "failed" {
                            let message = components.queryItems?.first(where: { $0.name == "message" })?.value
                            throw BackendImportError.serverError(message ?? "Authentication failed.")
                        }

                        let importResult = try await self.authClient.fetchImportResult(sessionID: sessionID)
                        try await self.transactionRepository.replaceAll(with: importResult.transactions)
                        self.transactions = await self.transactionRepository.fetchAll()
                        self.connectionState = .connected(importedCount: self.transactions.count)
                        self.selectedTab = .transactions
                    } catch {
                        self.connectionState = .failed(error.localizedDescription)
                        self.alertMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            connectionState = .failed(error.localizedDescription)
            alertMessage = error.localizedDescription
            isImporting = false
        }
    }

    func clearTransactions() async {
        do {
            try await transactionRepository.clear()
            transactions = await transactionRepository.fetchAll()
            connectionState = .notConnected
        } catch {
            alertMessage = error.localizedDescription
        }
    }
    
    func clearConnectionState() {
        connectionState = .notConnected
    }
    
    private func persistConnectionState() {
        do {
            let persisted = connectionState.persistedValue
            let data = try JSONEncoder().encode(persisted)
            defaults.set(data, forKey: connectionStateKey)
        } catch {
            print("Failed to persist connection states", error)
        }
    }
    
    private static func loadPersistedConnectionState(from defaults: UserDefaults) -> BankConnectionState {
        guard
            let data = defaults.data(forKey: "app.connectionState"),
            let persisted = try? JSONDecoder().decode(PersistedConnectionState.self, from: data)
        else {
            return .notConnected
        }

        return .fromPersisted(persisted)
    }
}

enum PersistedConnectionState: Codable {
    case notConnected
    case connected(importedCount: Int)
    case failed(String)
}

extension BankConnectionState {
    var persistedValue: PersistedConnectionState {
        switch self {
        case .notConnected:
            return .notConnected
        case .connected(let importedCount):
            return .connected(importedCount: importedCount)
        case .failed(let message):
            return .failed(message)
        case .importing:
            // Don't restore an in-flight import after relaunch
            return .notConnected
        }
    }

    static func fromPersisted(_ persisted: PersistedConnectionState) -> BankConnectionState {
        switch persisted {
        case .notConnected:
            return .notConnected
        case .connected(let importedCount):
            return .connected(importedCount: importedCount)
        case .failed(let message):
            return .failed(message)
        }
    }
}
