//
//  BankConnectionState.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

struct BankConnection: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let providerID: String
    var displayName: String
    var status: Status
    var importedCount: Int
    var lastSyncedAt: Date?

    enum Status: Equatable, Codable, Hashable {
        case importing
        case connected
        case failed(String)
    }

    init(
        providerID: String,
        displayName: String,
        status: Status = .importing,
        importedCount: Int = 0,
        lastSyncedAt: Date? = nil
    ) {
        self.id = providerID
        self.providerID = providerID
        self.displayName = displayName
        self.status = status
        self.importedCount = importedCount
        self.lastSyncedAt = lastSyncedAt
    }
}
