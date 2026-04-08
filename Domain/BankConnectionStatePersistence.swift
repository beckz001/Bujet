//
//  ConnectionStatePersistence.swift
//  Bujet
//
//  Created by Zachary Beck on 28/03/2026.
//

import Foundation

enum PersistedConnectionState: Codable {
    case notConnected
    case connected(importedCount: Int)
    case failed(String)
}

extension BankConnectionStateModel {
    /// Only stable states should be persisted.
    var persistedValue: PersistedConnectionState? {
        switch self {
        case .notConnected:
            return .notConnected
        case .connected(let importedCount):
            return .connected(importedCount: importedCount)
        case .failed(let message):
            return .failed(message)
        case .importing:
            // Don't persist transient importing state
            return nil
        }
    }

    static func fromPersisted(_ persisted: PersistedConnectionState) -> BankConnectionStateModel {
        switch persisted {
        case .notConnected:
            return .notConnected
        case .connected(let importedCount):
            return .connected(importedCount: importedCount)
        case .failed(let message):
            return .failed(message)
        }
    }
}

