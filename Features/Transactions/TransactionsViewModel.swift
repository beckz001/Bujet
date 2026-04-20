//
//  TransactionsViewModel.swift
//  Bujet
//
//  Created by Zachary Beck on 28/03/2026.
//

import Foundation
import Observation

enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case imported = "Imported"
    case manual = "Manual"
}

@MainActor
@Observable
final class TransactionsViewModel {
    private let transactionRepository: any TransactionRepository
    var transactions: [Transaction] = []
    var filter: TransactionFilter = .all

    var filteredTransactions: [Transaction] {
        switch filter {
        case .all: return transactions
        case .imported: return transactions.filter { $0.source == .imported }
        case .manual: return transactions.filter { $0.source == .manual }
        }
    }

    init(transactionRepository: some TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func loadTransactions() async {
        transactions = await transactionRepository.fetchAll()
    }

    func refresh() async {
        await loadTransactions()
    }
}
