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

    // MARK: - Pending import state
    var pendingImportSession: TransactionImportSession?
    var selectedImportRange: ImportDateRange?
    var activeImportBoundary: ImportRangeBoundary = .start
    var activeImportSheet: ImportSheet?
    var isFinalisingImport = false
    var isSwitchingImportSheet = false
    var didCommitImport = false
    var importDismissReason: ImportDismissReason?

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
        connectionStore.isImporting || isFinalisingImport
    }

    var pendingImportCount: Int {
        pendingImportSession?.totalCount ?? 0
    }

    var selectedImportPreviewCount: Int {
        guard let pendingImportSession, let selectedImportRange else {
            return 0
        }
        return pendingImportSession.previewCount(in: selectedImportRange)
    }

    var currentCalendarSelectionDate: Date {
        guard let selectedImportRange else {
            return Date()
        }

        switch activeImportBoundary {
        case .start:
            return selectedImportRange.startDate
        case .end:
            return selectedImportRange.endDate
        }
    }

    var canCommitPendingImport: Bool {
        pendingImportSession != nil &&
        selectedImportRange != nil &&
        selectedImportPreviewCount > 0 &&
        !isFinalisingImport
    }
    
    var selectableCalendarRange: ClosedRange<Date> {
        guard
            let pendingImportSession,
            let selectedImportRange
        else {
            let today = Calendar.current.startOfDay(for: Date())
            return today...today
        }

        switch activeImportBoundary {
        case .start:
            // Start can move anywhere from the imported minimum up to the current end
            return pendingImportSession.availableRange.lowerBound...selectedImportRange.endDate

        case .end:
            // End can move anywhere from the current start up to the imported maximum
            return selectedImportRange.startDate...pendingImportSession.availableRange.upperBound
        }
    }

    // MARK: - Import flow

    func startTrueLayerFlow(onImportSuccess: (() -> Void)? = nil) async {
        alertMessage = nil
        clearPendingImportState()
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
                            onImportSuccess?()
                            return
                        }

                        self.preparePendingImport(with: importedTransactions)
                    } catch {
                        self.presentImportFlowError(error)
                    }
                }
            }
        } catch {
            presentServerConnectionError(error)
        }
    }

    func showImportRangeSheet() {
        guard pendingImportSession != nil else { return }
        isSwitchingImportSheet = true
        importDismissReason = .switching
        activeImportSheet = .dateRange
    }

    func setActiveImportBoundary(_ boundary: ImportRangeBoundary) {
        activeImportBoundary = boundary
    }

    func setCalendarSelectionDate(_ date: Date) {
        guard let pendingImportSession, var selectedImportRange else { return }

        let normalizedDate = pendingImportSession.calendar.startOfDay(for: date)

        switch activeImportBoundary {
        case .start:
            guard normalizedDate <= selectedImportRange.endDate else { return }
            selectedImportRange.startDate = normalizedDate

        case .end:
            guard normalizedDate >= selectedImportRange.startDate else { return }
            selectedImportRange.endDate = normalizedDate
        }

        self.selectedImportRange = selectedImportRange
    }

    func commitFullPendingImport(onImportSuccess: (() -> Void)? = nil) async {
        guard let pendingImportSession else { return }

        selectedImportRange = ImportDateRange(
            startDate: pendingImportSession.availableRange.lowerBound,
            endDate: pendingImportSession.availableRange.upperBound
        )

        await commitPendingImport(onImportSuccess: onImportSuccess)
    }

    func commitPendingImport(onImportSuccess: (() -> Void)? = nil) async {
        guard
            let pendingImportSession,
            let selectedImportRange
        else {
            return
        }

        isFinalisingImport = true

        do {
            let filteredTransactions =
                pendingImportSession.filteredTransactions(in: selectedImportRange)

            importDismissReason = .commit
            activeImportSheet = nil

            try await transactionRepository.replaceAll(with: filteredTransactions)

            connectionStore.connectionState =
                .connected(importedCount: filteredTransactions.count)

            isFinalisingImport = false
            onImportSuccess?()

        } catch {
            let message = error.localizedDescription

            connectionStore.connectionState = .failed(message)
            connectionAlert = .serverConnection(message: message)

            isFinalisingImport = false
        }
    }

    func cancelPendingImport() {
        clearPendingImportState()
        connectionStore.reset()
    }

    private func preparePendingImport(with transactions: [Transaction]) {
        guard let session = TransactionImportSession(transactions: transactions) else {
            connectionStore.reset()
            return
        }

        pendingImportSession = session
        selectedImportRange = ImportDateRange(
            startDate: session.availableRange.lowerBound,
            endDate: session.availableRange.upperBound
        )
        activeImportBoundary = .start
        activeImportSheet = .options
    }

    func clearPendingImportState() {
        pendingImportSession = nil
        selectedImportRange = nil
        activeImportBoundary = .start
        activeImportSheet = nil
        isFinalisingImport = false
    }

    // MARK: - Transaction/state/errors

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
        clearPendingImportState()

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

    func presentImportFlowError(_ error: Error) {
        clearPendingImportState()

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
    
    enum ImportDismissReason {
        case commit
        case cancel
        case switching
    }
}

