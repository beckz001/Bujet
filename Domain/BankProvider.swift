//
//  BankProvider.swift
//  Bujet
//
//  Created by Zachary Beck on 30/04/2026.
//

import SwiftUI

/// A bank the user can connect to via the TrueLayer sandbox. The `id` must
/// match the TrueLayer provider identifier the backend expects.
struct BankProvider: Identifiable, Hashable {
    let id: String
    let displayName: String
    let iconSystemName: String
    let tint: Color
}

extension BankProvider {
    /// Curated list of major UK retail banks. IDs use TrueLayer's `ob-<bank>`
    /// Open Banking provider convention. Backend forwards these via the
    /// `provider_id` query param so TrueLayer skips the bank picker.
    static let ukCatalog: [BankProvider] = [
        BankProvider(id: "ob-lloyds", displayName: "Lloyds Bank", iconSystemName: "building.columns.fill", tint: .green),
        BankProvider(id: "ob-barclays", displayName: "Barclays", iconSystemName: "building.columns.fill", tint: .cyan),
        BankProvider(id: "ob-hsbc", displayName: "HSBC", iconSystemName: "building.columns.fill", tint: .red),
        BankProvider(id: "ob-natwest", displayName: "NatWest", iconSystemName: "building.columns.fill", tint: .purple),
        BankProvider(id: "ob-santander", displayName: "Santander", iconSystemName: "building.columns.fill", tint: .red),
        BankProvider(id: "ob-halifax", displayName: "Halifax", iconSystemName: "building.columns.fill", tint: .blue),
        BankProvider(id: "ob-nationwide", displayName: "Nationwide", iconSystemName: "building.columns.fill", tint: .blue),
        BankProvider(id: "ob-rbs", displayName: "Royal Bank of Scotland", iconSystemName: "building.columns.fill", tint: .indigo),
        BankProvider(id: "ob-monzo", displayName: "Monzo", iconSystemName: "creditcard.fill", tint: .pink),
        BankProvider(id: "ob-starling", displayName: "Starling Bank", iconSystemName: "creditcard.fill", tint: .indigo),
        BankProvider(id: "ob-revolut", displayName: "Revolut", iconSystemName: "creditcard.fill", tint: .primary),
        BankProvider(id: "ob-tsb", displayName: "TSB", iconSystemName: "building.columns.fill", tint: .blue),
        BankProvider(id: "ob-first-direct", displayName: "First Direct", iconSystemName: "building.columns.fill", tint: .black),
    ]
}
