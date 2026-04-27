//
//  TransactionsViewModel.swift
//  Bujet
//
//  Created by Zachary Beck on 28/03/2026.
//

import Foundation
import Observation

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case manual = "Manual"
    case imported = "Imported"

    var id: String { rawValue }
}

@MainActor
@Observable
final class TransactionsViewModel {
    @ObservationIgnored private let transactionRepository: any TransactionRepository
    @ObservationIgnored private let insights = TransactionInsights()

    var transactions: [Transaction] = []
    var filter: TransactionFilter = .all
    var searchText: String = ""

    init(transactionRepository: some TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func loadTransactions() async {
        transactions = await transactionRepository.fetchAll()
    }

    func refresh() async {
        await loadTransactions()
    }

    var filteredTransactions: [Transaction] {
        let bySource: [Transaction]
        switch filter {
        case .all:      bySource = transactions
        case .imported: bySource = transactions.filter { $0.source == .imported }
        case .manual:   bySource = transactions.filter { $0.source == .manual }
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return bySource }
        return bySource.filter {
            $0.merchantName.lowercased().contains(trimmed)
                || $0.description.lowercased().contains(trimmed)
        }
    }

    var groupedByDay: [DayGroup] {
        insights.groupedByDay(from: filteredTransactions).map {
            DayGroup(day: $0.day, transactions: $0.transactions)
        }
    }

    struct DayGroup: Identifiable {
        let day: Date
        let transactions: [Transaction]
        var id: Date { day }
    }
}
