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
    let category: TransactionCategory
    let bankConnectionID: String?

    var isDebit: Bool {
        amount < 0
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, description, merchantName, amount, currencyCode, source, category, classification, bankConnectionID
    }

    // Backend payloads omit `source` and `category` but include `classification`;
    // locally persisted transactions include `source` and `category`. Try stored
    // fields first, derive via the categoriser otherwise.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        description = try c.decode(String.self, forKey: .description)
        merchantName = try c.decode(String.self, forKey: .merchantName)
        amount = try c.decode(Double.self, forKey: .amount)
        currencyCode = try c.decode(String.self, forKey: .currencyCode)
        source = try c.decodeIfPresent(TransactionSource.self, forKey: .source) ?? .imported
        bankConnectionID = try c.decodeIfPresent(String.self, forKey: .bankConnectionID)

        if let stored = try c.decodeIfPresent(TransactionCategory.self, forKey: .category) {
            category = stored
        } else {
            let classifications = try c.decodeIfPresent([String].self, forKey: .classification)
            category = TransactionCategoriser.categorise(
                classifications: classifications,
                merchant: merchantName
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(description, forKey: .description)
        try c.encode(merchantName, forKey: .merchantName)
        try c.encode(amount, forKey: .amount)
        try c.encode(currencyCode, forKey: .currencyCode)
        try c.encode(source, forKey: .source)
        try c.encode(category, forKey: .category)
        try c.encodeIfPresent(bankConnectionID, forKey: .bankConnectionID)
    }

    init(id: String, date: Date, description: String, merchantName: String,
         amount: Double, currencyCode: String, source: TransactionSource,
         category: TransactionCategory, bankConnectionID: String? = nil) {
        self.id = id
        self.date = date
        self.description = description
        self.merchantName = merchantName
        self.amount = amount
        self.currencyCode = currencyCode
        self.source = source
        self.category = category
        self.bankConnectionID = bankConnectionID
    }
}
