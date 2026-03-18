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
    private let importService: any PhaseAImportService

    var selectedTab: AppTab = .home
    var connectionState: BankConnectionState = .notConnected
    var pastedAuthCode = ""
    var transactions: [Transaction] = []
    var isImporting = false
    var alertMessage: String?

    init(
        transactionRepository: some TransactionRepository,
        importService: some PhaseAImportService
    ) {
        self.transactionRepository = transactionRepository
        self.importService = importService
    }

    func loadTransactions() async {
        transactions = await transactionRepository.fetchAll()
    }

    func importTransactionsFromPastedCode() async {
        let trimmedCode = pastedAuthCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty else {
            alertMessage = "Paste the TrueLayer authentication code first."
            connectionState = .failed("No authentication code was provided.")
            return
        }

        isImporting = true
        connectionState = .importing

        do {
            let importedTransactions = try await importService.importTransactions(using: trimmedCode)
            try await transactionRepository.replaceAll(with: importedTransactions)
            transactions = await transactionRepository.fetchAll()
            connectionState = .connected(importedCount: transactions.count)
            pastedAuthCode = ""
        } catch {
            connectionState = .failed(error.localizedDescription)
            alertMessage = error.localizedDescription
        }

        isImporting = false
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
}
