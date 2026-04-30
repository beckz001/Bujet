//
//  BankConnectionStatePersistence.swift
//  Bujet
//
//  Created by Zachary Beck on 28/03/2026.
//

import Foundation

/// Storage key holding the legacy single-connection state, kept here so the
/// store can detect and discard it during the move to multi-connection.
enum LegacyBankConnectionStorage {
    static let key = "app.connectionState"
}
