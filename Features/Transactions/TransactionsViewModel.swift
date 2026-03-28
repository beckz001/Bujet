//
//  TransactionsViewModel.swift
//  Bujet
//
//  Created by Zachary Beck on 28/03/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class TransactionsViewModel {
    private let transactionRepository: any TransactionRepository

    var transactions: [Transaction] = []
    //var alertMessage: String?

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
