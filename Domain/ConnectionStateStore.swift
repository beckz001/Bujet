//
//  ConnectionStateStore.swift
//  Bujet
//
//  Created by Zachary Beck on 28/03/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class ConnectionStateStore {
    @ObservationIgnored
    private let defaults: UserDefaults

    @ObservationIgnored
    private static let connectionStateKey = "app.connectionState"

    var connectionState: BankConnectionState = .notConnected {
        didSet {
            persistConnectionStateIfNeeded()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.connectionState = Self.loadPersistedConnectionState(from: defaults)
    }

    var isImporting: Bool {
        if case .importing = connectionState {
            return true
        }
        return false
    }

    var bannerState: HomeBannerState {
        switch connectionState {
        case .connected:
            return .connected
        case .importing:
            return .dataPending
        case .failed:
            return .importFailed
        case .notConnected:
            return .disconnected
        }
    }

    func reset() {
        connectionState = .notConnected
    }

    // MARK: - Persistence

    private func persistConnectionStateIfNeeded() {
        guard let persisted = connectionState.persistedValue else {
            // Don't persist transient in-flight importing state
            return
        }

        do {
            let data = try JSONEncoder().encode(persisted)
            defaults.set(data, forKey: Self.connectionStateKey)
        } catch {
            print("Failed to persist connection state:", error)
        }
    }

    private static func loadPersistedConnectionState(from defaults: UserDefaults) -> BankConnectionState {
        guard
            let data = defaults.data(forKey: connectionStateKey),
            let persisted = try? JSONDecoder().decode(PersistedConnectionState.self, from: data)
        else {
            return .notConnected
        }

        return .fromPersisted(persisted)
    }
}
