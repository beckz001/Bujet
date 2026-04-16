//
//  TransactionImportSession.swift
//  Bujet
//
//  Created by Zachary Beck on 15/04/2026.
//

import Foundation

struct TransactionImportSession {
    let rawTransactions: [Transaction]
    let availableRange: ClosedRange<Date>
    let calendar: Calendar

    init?(transactions: [Transaction], calendar: Calendar = .current) {
        guard
            let minDate = transactions.map(\.date).min(),
            let maxDate = transactions.map(\.date).max()
        else {
            return nil
        }

        self.calendar = calendar
        self.rawTransactions = transactions
        self.availableRange = calendar.startOfDay(for: minDate)...calendar.startOfDay(for: maxDate)
    }

    var totalCount: Int {
        rawTransactions.count
    }

    func filteredTransactions(in selectedRange: ImportDateRange) -> [Transaction] {
        let lowerBound = calendar.startOfDay(for: selectedRange.startDate)
        let upperBound = calendar.startOfDay(for: selectedRange.endDate)

        return rawTransactions.filter { transaction in
            let transactionDate = calendar.startOfDay(for: transaction.date)
            return transactionDate >= lowerBound && transactionDate <= upperBound
        }
    }

    func previewCount(in selectedRange: ImportDateRange) -> Int {
        filteredTransactions(in: selectedRange).count
    }
}
