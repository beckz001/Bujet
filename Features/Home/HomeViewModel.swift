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
    @ObservationIgnored private let transactionRepository: any TransactionRepository
    @ObservationIgnored private let authClient: BackendAuthClient
    @ObservationIgnored private let authService = TrueLayerAuthService()
    @ObservationIgnored private let connectionStore: BankConnectionStateStore

    var alertMessage: String?
    var connectionAlert: ConnectionAlert?

    /// Non-nil while a bank import is being reviewed/committed.
    /// Drives the import sheet presentation from `HomeView`.
    var activeImportFlow: TransactionImportFlow?

    /// Caller-supplied success hook from `startBankConnection`, fired once the
    /// active import flow commits successfully.
    @ObservationIgnored private var onImportSuccess: (() -> Void)?

    init(
        transactionRepository: some TransactionRepository,
        authClient: BackendAuthClient,
        connectionStore: BankConnectionStateStore
    ) {
        self.transactionRepository = transactionRepository
        self.authClient = authClient
        self.connectionStore = connectionStore
    }

    // MARK: - Derived connection state

    var connectionState: BankConnectionState {
        connectionStore.connectionState
    }

    var bannerState: ConnectionBannerState {
        connectionStore.bannerState
    }

    var isImporting: Bool {
        connectionStore.isImporting || (activeImportFlow?.isFinalising ?? false)
    }

    // MARK: - Bank connection + import flow

    func startBankConnection(onImportSuccess: (() -> Void)? = nil) async {
        alertMessage = nil
        activeImportFlow = nil
        self.onImportSuccess = onImportSuccess
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
                        let importedTransactions = importResult.transactions

                        if importedTransactions.isEmpty {
                            try await self.transactionRepository.replaceAll(with: [])
                            self.connectionStore.connectionState = .connected(importedCount: 0)
                            self.onImportSuccess?()
                            self.onImportSuccess = nil
                            return
                        }

                        self.beginImport(with: importedTransactions)
                    } catch {
                        self.presentImportFlowError(error)
                    }
                }
            }
        } catch {
            presentServerConnectionError(error)
        }
    }

    private func beginImport(with transactions: [Transaction]) {
        guard let session = TransactionImportSession(transactions: transactions) else {
            connectionStore.reset()
            onImportSuccess = nil
            return
        }

        activeImportFlow = TransactionImportFlow(
            session: session,
            transactionRepository: transactionRepository,
            onCommit: { [weak self] count in
                self?.handleImportCommitted(count: count)
            },
            onCancel: { [weak self] in
                self?.handleImportCancelled()
            },
            onFailed: { [weak self] error in
                self?.handleImportFailed(error)
            }
        )
    }

    private func handleImportCommitted(count: Int) {
        connectionStore.connectionState = .connected(importedCount: count)
        activeImportFlow = nil
        onImportSuccess?()
        onImportSuccess = nil
    }

    private func handleImportCancelled() {
        activeImportFlow = nil
        connectionStore.reset()
        onImportSuccess = nil
    }

    private func handleImportFailed(_ error: Error) {
        activeImportFlow = nil
        onImportSuccess = nil
        let message = error.localizedDescription
        connectionStore.connectionState = .failed(message)
        connectionAlert = .serverConnection(message: message)
    }

    /// Called from `HomeView`'s sheet `onDismiss`. Handles the swipe-to-dismiss
    /// case where no commit/cancel callback has fired yet.
    func handleImportSheetDismissal() {
        if case .importing = connectionStore.connectionState {
            connectionStore.reset()
        }
        activeImportFlow = nil
        onImportSuccess = nil
    }

    // MARK: - Transactions + alerts

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

    private func presentServerConnectionError(_ error: Error) {
        activeImportFlow = nil
        onImportSuccess = nil

        let fullError = error.localizedDescription
        connectionStore.connectionState = .failed(fullError)

        #if DEBUG
        connectionAlert = .serverConnection(message: fullError)
        #else
        connectionAlert = .serverConnection(
            message: "Unable to connect to the server. Please try again later."
        )
        #endif
    }

    private func presentImportFlowError(_ error: Error) {
        activeImportFlow = nil
        onImportSuccess = nil

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
