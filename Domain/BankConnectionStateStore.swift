//
//  BankConnectionStateStore.swift
//  Bujet
//
//  Created by Zachary Beck on 28/03/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class BankConnectionStateStore {
    @ObservationIgnored
    private let defaults: UserDefaults

    @ObservationIgnored
    private static let connectionsKey = "app.bankConnections"

    var connections: [BankConnection] = [] {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.removeObject(forKey: LegacyBankConnectionStorage.key)
        self.connections = Self.loadPersistedConnections(from: defaults)
        // Re-persist after filtering to remove any stale .importing entries from storage
        persist()
    }

    // MARK: - Derived

    var hasAnyConnection: Bool { !connections.isEmpty }

    var isImporting: Bool {
        connections.contains { $0.status == .importing }
    }

    var bannerState: ConnectionBannerState {
        if connections.isEmpty { return .disconnected }
        if isImporting { return .dataPending }
        if connections.contains(where: { if case .connected = $0.status { return true } else { return false } }) {
            return .connected
        }
        if connections.contains(where: { if case .failed = $0.status { return true } else { return false } }) {
            return .importFailed
        }
        return .disconnected
    }

    func connection(for providerID: String) -> BankConnection? {
        connections.first { $0.providerID == providerID }
    }

    // MARK: - Mutations

    func setImporting(providerID: String, displayName: String) {
        upsert(BankConnection(providerID: providerID, displayName: displayName, status: .importing))
    }

    func setConnected(providerID: String, displayName: String, importedCount: Int) {
        var connection = connection(for: providerID)
            ?? BankConnection(providerID: providerID, displayName: displayName)
        connection.displayName = displayName
        connection.status = .connected
        connection.importedCount = importedCount
        connection.lastSyncedAt = Date()
        upsert(connection)
    }

    func setFailed(providerID: String, displayName: String, message: String) {
        var connection = connection(for: providerID)
            ?? BankConnection(providerID: providerID, displayName: displayName)
        connection.displayName = displayName
        connection.status = .failed(message)
        upsert(connection)
    }

    func remove(providerID: String) {
        connections.removeAll { $0.providerID == providerID }
    }

    /// Drops the in-flight import, used when the user cancels mid-flow.
    func cancelImporting(providerID: String) {
        guard let existing = connection(for: providerID), existing.status == .importing else { return }
        remove(providerID: providerID)
    }

    func reset() {
        connections = []
    }

    // MARK: - Persistence

    private func upsert(_ connection: BankConnection) {
        if let index = connections.firstIndex(where: { $0.providerID == connection.providerID }) {
            connections[index] = connection
        } else {
            connections.append(connection)
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(connections)
            defaults.set(data, forKey: Self.connectionsKey)
        } catch {
            print("Failed to persist bank connections:", error)
        }
    }

    private static func loadPersistedConnections(from defaults: UserDefaults) -> [BankConnection] {
        guard
            let data = defaults.data(forKey: connectionsKey),
            let connections = try? JSONDecoder().decode([BankConnection].self, from: data)
        else {
            return []
        }
        // Filter out any connections stuck in .importing state - this is a transient
        // state that should never persist across app launches. If the user closed
        // the app mid-auth, that flow is dead and should be cleared.
        return connections.filter { connection in
            if case .importing = connection.status { return false }
            return true
        }
    }
}
