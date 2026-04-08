//
//  HomeViewModel.swift
//  Bujet
//
//  Created by Zachary Beck on 28/03/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let transactionRepository: any TransactionRepository
    private let authClient: BackendAuthClient
    private let authService = TrueLayerAuthService()
    private let connectionStore: BankConnectionStateStore

    var alertMessage: String?
    var connectionAlert: ConnectionAlert?

    init(
        transactionRepository: some TransactionRepository,
        authClient: BackendAuthClient,
        connectionStore: BankConnectionStateStore
    ) {
        self.transactionRepository = transactionRepository
        self.authClient = authClient
        self.connectionStore = connectionStore
    }

    var connectionState: BankConnectionStateModel {
        connectionStore.connectionState
    }

    var bannerState: ConnectionStateModel {
        connectionStore.bannerState
    }

    var isImporting: Bool {
        connectionStore.isImporting
    }

    func startTrueLayerFlow(onImportSuccess: (() -> Void)? = nil) async {
        alertMessage = nil
        connectionStore.connectionState = .importing

        do {
            let startResponse = try await authClient.startAuth()

            authService.start(authURL: startResponse.authURL) { [weak self] result in
                guard let self else { return }

                Task { @MainActor in
                    do {
                        let callbackURL = try result.get()

                        guard
                            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                            let sessionID = components.queryItems?.first(where: { $0.name == "session_id" })?.value,
                            let status = components.queryItems?.first(where: { $0.name == "status" })?.value
                        else {
                            throw AuthFlowError.invalidCallback
                        }

                        if status == "failed" {
                            let message = components.queryItems?.first(where: { $0.name == "message" })?.value
                            throw BackendImportError.serverError(message ?? "Authentication failed.")
                        }

                        let importResult = try await self.authClient.fetchImportResult(sessionID: sessionID)
                        try await self.transactionRepository.replaceAll(with: importResult.transactions)

                        let transactions = await self.transactionRepository.fetchAll()
                        self.connectionStore.connectionState = .connected(importedCount: transactions.count)
                        onImportSuccess?()

                    } catch {
                        self.presentImportFlowError(error)
                    }
                }
            }
        } catch {
            presentServerConnectionError(error)
        }
    }

    func clearTransactions() async {
        do {
            try await transactionRepository.clear()
            connectionStore.reset()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func clearConnectionState() {
        connectionStore.reset()
    }
    
    func presentServerConnectionError(_ error: Error) {
        let fullError = error.localizedDescription

        connectionStore.connectionState = .failed(fullError)
        print("Connection error: \(fullError)")

        #if DEBUG
        connectionAlert = .serverConnection(message: fullError)
        #else
        connectionAlert = .serverConnection(
            message: "Unable to connect to the server. Please try again later."
        )
        #endif
    }

    func presentImportFlowError(_ error: Error) {
        #if DEBUG
        print("Import/auth error: \(error.localizedDescription)")
        #endif

        if let payload = TrueLayerAPIErrorParser.parse(from: error) {
            connectionStore.connectionState = .failed(payload.errorDescription)
            connectionAlert = .dataAPIError(
                title: payload.error.formattedErrorAlertTitle,
                message: payload.errorDescription
            )
            return
        }

        connectionAlert = .connectionCancelled
    }
    
    func clearErrorAlert() {
        connectionAlert = nil
        alertMessage = nil
        connectionStore.reset()
    }

    enum ConnectionAlert: Identifiable, Equatable {
        case serverConnection(message: String)
        case connectionCancelled
        case dataAPIError(title: String, message: String)

        var id: String {
            switch self {
            case .serverConnection(let message):
                return "serverConnection-\(message)"
            case .connectionCancelled:
                return "connectionCancelled"
            case .dataAPIError(let title, let message):
                return "dataAPIError-\(title)-\(message)"
            }
        }
    }
}
