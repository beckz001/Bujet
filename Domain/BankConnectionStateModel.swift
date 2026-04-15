//
//  BankConnectionState.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

enum BankConnectionStateModel: Equatable {
    case notConnected
    case importing
    case connected(importedCount: Int)
    case failed(String)

    var title: String {
        switch self {
        case .notConnected:
            "Not Connected"
        case .importing:
            "Importing"
        case .connected:
            "Connected"
        case .failed:
            "Import Failed"
        }
    }
}
