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
    private let connectionStore: ConnectionStateStore

    var pastedAuthCode = ""
    var alertMessage: String?

    init(
        transactionRepository: some TransactionRepository,
        authClient: BackendAuthClient,
        connectionStore: ConnectionStateStore
    ) {
        self.transactionRepository = transactionRepository
        self.authClient = authClient
        self.connectionStore = connectionStore
    }

    var connectionState: BankConnectionState {
        connectionStore.connectionState
    }

    var bannerState: HomeBannerState {
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
                        self.connectionStore.connectionState = .failed(error.localizedDescription)
                        self.alertMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            connectionStore.connectionState = .failed(error.localizedDescription)
            alertMessage = error.localizedDescription
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
}
