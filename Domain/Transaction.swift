//
//  Transaction.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

struct Transaction: Identifiable, Codable, Hashable {
    let id: String
    let date: Date
    let description: String
    let merchantName: String
    let amount: Double
    let currencyCode: String

    var isDebit: Bool {
        amount < 0
    }
}
