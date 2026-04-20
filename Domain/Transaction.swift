//
//  Transaction.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

enum TransactionSource: String, Codable {
    case imported
    case manual
}

struct Transaction: Identifiable, Codable, Hashable {
    let id: String
    let date: Date
    let description: String
    let merchantName: String
    let amount: Double
    let currencyCode: String
    let source: TransactionSource

    var isDebit: Bool {
        amount < 0
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, description, merchantName, amount, currencyCode, source
    }

    // Defaults `source` to `.imported` when absent — backend responses don't include this field.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        description = try c.decode(String.self, forKey: .description)
        merchantName = try c.decode(String.self, forKey: .merchantName)
        amount = try c.decode(Double.self, forKey: .amount)
        currencyCode = try c.decode(String.self, forKey: .currencyCode)
        source = try c.decodeIfPresent(TransactionSource.self, forKey: .source) ?? .imported
    }

    init(id: String, date: Date, description: String, merchantName: String,
         amount: Double, currencyCode: String, source: TransactionSource) {
        self.id = id
        self.date = date
        self.description = description
        self.merchantName = merchantName
        self.amount = amount
        self.currencyCode = currencyCode
        self.source = source
    }
}
