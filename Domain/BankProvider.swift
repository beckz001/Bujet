//
//  BankProvider.swift
//  Bujet
//
//  Created by Zachary Beck on 30/04/2026.
//

import SwiftUI

/// A bank the user can connect to via the TrueLayer sandbox.
///
/// `id` is the local, app-facing identifier used to tag transactions and
/// group connections in the UI. `truelayerProviderID` is what gets sent to
/// TrueLayer's auth flow — in the sandbox the only accepted value is
/// `"mock"`, so every entry uses that until production credentials are wired
/// up and the real `ob-<bank>` IDs become valid.
struct BankProvider: Identifiable, Hashable {
    let id: String
    let truelayerProviderID: String
    let displayName: String
    let iconSystemName: String
    let tint: Color
}

extension BankProvider {
    /// Curated list of major UK retail banks. The local `id` uses TrueLayer's
    /// `ob-<bank>` naming for clarity, but every entry routes through the
    /// `mock` sandbox provider until production access is granted.
    static let ukCatalog: [BankProvider] = [
        BankProvider(id: "ob-lloyds", truelayerProviderID: "mock", displayName: "Lloyds Bank", iconSystemName: "building.columns.fill", tint: .green),
        BankProvider(id: "ob-barclays", truelayerProviderID: "mock", displayName: "Barclays", iconSystemName: "building.columns.fill", tint: .cyan),
        BankProvider(id: "ob-hsbc", truelayerProviderID: "mock", displayName: "HSBC", iconSystemName: "building.columns.fill", tint: .red),
        BankProvider(id: "ob-natwest", truelayerProviderID: "mock", displayName: "NatWest", iconSystemName: "building.columns.fill", tint: .purple),
        BankProvider(id: "ob-santander", truelayerProviderID: "mock", displayName: "Santander", iconSystemName: "building.columns.fill", tint: .red),
        BankProvider(id: "ob-halifax", truelayerProviderID: "mock", displayName: "Halifax", iconSystemName: "building.columns.fill", tint: .blue),
        BankProvider(id: "ob-nationwide", truelayerProviderID: "mock", displayName: "Nationwide", iconSystemName: "building.columns.fill", tint: .blue),
        BankProvider(id: "ob-rbs", truelayerProviderID: "mock", displayName: "Royal Bank of Scotland", iconSystemName: "building.columns.fill", tint: .indigo),
        BankProvider(id: "ob-monzo", truelayerProviderID: "mock", displayName: "Monzo", iconSystemName: "creditcard.fill", tint: .pink),
        BankProvider(id: "ob-starling", truelayerProviderID: "mock", displayName: "Starling Bank", iconSystemName: "creditcard.fill", tint: .indigo),
        BankProvider(id: "ob-revolut", truelayerProviderID: "mock", displayName: "Revolut", iconSystemName: "creditcard.fill", tint: .primary),
        BankProvider(id: "ob-tsb", truelayerProviderID: "mock", displayName: "TSB", iconSystemName: "building.columns.fill", tint: .blue),
        BankProvider(id: "ob-first-direct", truelayerProviderID: "mock", displayName: "First Direct", iconSystemName: "building.columns.fill", tint: .black),
    ]
}
