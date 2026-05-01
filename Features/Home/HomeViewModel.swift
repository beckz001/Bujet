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
    @ObservationIgnored private let connector: any BankConnecting
    @ObservationIgnored private let connectionStore: BankConnectionStateStore
    @ObservationIgnored private let insights = TransactionInsights()
    @ObservationIgnored private let calendar = Calendar.current

    var transactions: [Transaction] = []

    var connectionAlert: ConnectionAlert?

    /// Non-nil while a bank import is being reviewed/committed.
    /// Drives the import sheet presentation from `HomeView`.
    var activeImportFlow: TransactionImportFlow?

    /// Non-nil while a manual transaction entry sheet is open.
    var activeManualFlow: ManualTransactionFlow?

    /// Non-nil after a successful manual import — drives the success alert.
    var manualImportResult: ManualImportResult?

    struct ManualImportResult: Identifiable {
        let id = UUID()
        let count: Int
    }

    /// Binding source for the import sheet. Keying on `Step` (not the flow) makes
    /// SwiftUI dismiss + re-present between options and review, giving the
    /// natural slide-down / slide-up transition.
    var presentedImportSheet: TransactionImportFlow.Step? {
        get { activeImportFlow?.step }
        set {
            if let newValue {
                activeImportFlow?.step = newValue
            } else {
                activeImportFlow = nil
            }
        }
    }

    /// Caller-supplied success hook from `startBankConnection`, fired once the
    /// active import flow commits successfully.
    @ObservationIgnored private var onImportSuccess: (() -> Void)?

    init(
        transactionRepository: some TransactionRepository,
        connector: any BankConnecting,
        connectionStore: BankConnectionStateStore
    ) {
        self.transactionRepository = transactionRepository
        self.connector = connector
        self.connectionStore = connectionStore
    }

    // MARK: - Lifecycle

    func loadTransactions() async {
        transactions = await transactionRepository.fetchAll()
    }

    func refresh() async {
        await loadTransactions()
    }

    // MARK: - Derived display data

    /// Total outgoing spend in the current calendar month.
    func totalAmountMonth() -> Double {
        insights.totalAmount(in: Date(), from: transactions)
    }

    /// Spend trend for the current month-to-date vs the same day-range last month.
    func compareLastMonth() -> SpendTrend {
        insights.spendTrend(currentMonth: Date(), from: transactions)
    }

    /// Whole days remaining in the current calendar month, exclusive of today.
    func daysRemainingMonth() -> Int {
        let now = Date()
        guard
            let range = calendar.range(of: .day, in: .month, for: now)
        else { return 0 }
        let day = calendar.component(.day, from: now)
        return max(0, range.count - day)
    }

    /// 0...1 fraction of the current month already elapsed.
    var monthProgress: Double {
        let now = Date()
        guard let range = calendar.range(of: .day, in: .month, for: now), range.count > 0 else {
            return 0
        }
        let day = Double(calendar.component(.day, from: now))
        return day / Double(range.count)
    }

    /// Sum of debits dated today.
    func todaySpent() -> Double {
        insights.totalAmount(on: Date(), from: transactions)
    }

    /// Three most recent transactions, newest first.
    func recentTransactions() -> [Transaction] {
        insights.mostRecent(3, from: transactions)
    }

    var currencyCode: String {
        transactions.first?.currencyCode ?? Locale.current.currency?.identifier ?? "GBP"
    }

    /// Abbreviated previous month name for the trend pill (e.g. "MAR").
    var previousMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLL"
        let prev = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return formatter.string(from: prev).uppercased()
    }

    // MARK: - Derived connection state

    var bannerState: ConnectionBannerState {
        connectionStore.bannerState
    }

    var isImporting: Bool {
        connectionStore.isImporting || (activeImportFlow?.isFinalising ?? false)
    }

    var connectedProviderIDs: Set<String> {
        Set(connectionStore.connections.map(\.providerID))
    }

    var hasAnyConnection: Bool {
        connectionStore.hasAnyConnection
    }

    var availableProviders: [BankProvider] {
        BankProvider.ukCatalog
    }

    /// Drives the bank-picker sheet from `HomeView`.
    var isPresentingBankPicker: Bool = false

    /// Provider currently being connected, used to update the right
    /// `BankConnection` entry in the store as the flow progresses.
    @ObservationIgnored private var inFlightProvider: BankProvider?

    // MARK: - Manual transaction import

    func startManualImport() {
        activeManualFlow = ManualTransactionFlow(
            transactionRepository: transactionRepository,
            onCommit: { [weak self] count in
                self?.handleManualImportCommitted(count: count)
            },
            onCancel: { [weak self] in
                self?.activeManualFlow = nil
            },
            onFailed: { [weak self] error in
                self?.handleManualImportFailed(error)
            }
        )
    }

    private func handleManualImportCommitted(count: Int) {
        activeManualFlow = nil
        manualImportResult = ManualImportResult(count: count)
    }

    private func handleManualImportFailed(_ error: Error) {
        activeManualFlow = nil
        connectionAlert = .serverConnection(message: error.localizedDescription)
    }

    // MARK: - Bank connection + import flow

    func presentBankPicker() {
        isPresentingBankPicker = true
    }

    func dismissBankPicker() {
        isPresentingBankPicker = false
    }

    func startBankConnection(provider: BankProvider, onImportSuccess: (() -> Void)? = nil) async {
        activeImportFlow = nil
        self.onImportSuccess = onImportSuccess
        inFlightProvider = provider
        isPresentingBankPicker = false
        connectionStore.setImporting(
            providerID: provider.id,
            displayName: provider.displayName
        )

        do {
            let transactions = try await connector.connect(provider: provider)

            if transactions.isEmpty {
                try await transactionRepository.replaceImported(with: [])
                connectionStore.setConnected(
                    providerID: provider.id,
                    displayName: provider.displayName,
                    importedCount: 0
                )
                inFlightProvider = nil
                self.onImportSuccess?()
                self.onImportSuccess = nil
                return
            }

            beginImport(with: transactions)
        } catch {
            presentConnectionError(error)
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
        if let provider = inFlightProvider {
            connectionStore.setConnected(
                providerID: provider.id,
                displayName: provider.displayName,
                importedCount: count
            )
        }
        inFlightProvider = nil
        activeImportFlow = nil
        onImportSuccess?()
        onImportSuccess = nil
    }

    private func handleImportCancelled() {
        activeImportFlow = nil
        if let provider = inFlightProvider {
            connectionStore.cancelImporting(providerID: provider.id)
        }
        inFlightProvider = nil
        onImportSuccess = nil
    }

    private func handleImportFailed(_ error: Error) {
        activeImportFlow = nil
        onImportSuccess = nil
        let message = error.localizedDescription
        if let provider = inFlightProvider {
            connectionStore.setFailed(
                providerID: provider.id,
                displayName: provider.displayName,
                message: message
            )
        }
        inFlightProvider = nil
        connectionAlert = .serverConnection(message: message)
    }

    /// Called from `HomeView`'s sheet `onDismiss`. Fires on both real dismissals
    /// (swipe-down, cancel) and on step transitions where SwiftUI dismisses the
    /// old sheet before presenting the new one. Guard so step changes don't get
    /// treated as cancellations.
    func handleImportSheetDismissal() {
        guard activeImportFlow == nil else { return }

        if let provider = inFlightProvider, connectionStore.isImporting {
            connectionStore.cancelImporting(providerID: provider.id)
        }
        inFlightProvider = nil
        onImportSuccess = nil
    }

    // MARK: - Transactions + alerts

    func clearImported() async {
        do {
            try await transactionRepository.clear(source: .imported)
            connectionStore.reset()
            await loadTransactions()
        } catch {
            connectionAlert = .serverConnection(message: error.localizedDescription)
        }
    }

    func clearManual() async {
        do {
            try await transactionRepository.clear(source: .manual)
            await loadTransactions()
        } catch {
            connectionAlert = .serverConnection(message: error.localizedDescription)
        }
    }

    func clearConnectionState() {
        connectionStore.reset()
    }

    private func presentConnectionError(_ error: Error) {
        activeImportFlow = nil
        onImportSuccess = nil

        if let payload = TrueLayerAPIErrorParser.parse(from: error) {
            if let provider = inFlightProvider {
                connectionStore.cancelImporting(providerID: provider.id)
            }
            inFlightProvider = nil
            connectionAlert = .dataAPIError(
                title: payload.error.formattedErrorAlertTitle,
                message: payload.errorDescription
            )
            return
        }

        if error is BankConnectionError {
            connectionAlert = .connectionCancelled
            if let provider = inFlightProvider {
                connectionStore.cancelImporting(providerID: provider.id)
            }
            inFlightProvider = nil
            return
        }

        if let provider = inFlightProvider {
            connectionStore.cancelImporting(providerID: provider.id)
        }
        inFlightProvider = nil

        #if DEBUG
        connectionAlert = .serverConnection(message: error.localizedDescription)
        #else
        connectionAlert = .serverConnection(
            message: "Unable to connect to the server. Please try again later."
        )
        #endif
    }

    func clearErrorAlert() {
        connectionAlert = nil
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

        var alertTitle: String {
            switch self {
            case .serverConnection: "Connection Error"
            case .connectionCancelled: "Connection Cancelled"
            case .dataAPIError(let title, _): title
            }
        }

        var alertMessage: String {
            switch self {
            case .serverConnection(let message): message
            case .connectionCancelled: "Bank connection cancelled, no data was sent to the server."
            case .dataAPIError(_, let message): message
            }
        }
    }
}
