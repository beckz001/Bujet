//
//  BankConnectionState.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

enum BankConnectionState: Equatable {
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

    var systemImage: String {
        switch self {
        case .notConnected:
            "link"
        case .importing:
            "arrow.triangle.2.circlepath"
        case .connected:
            "checkmark.circle.fill"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }

    var tintDescription: String {
        switch self {
        case .notConnected:
            "Secondary"
        case .importing:
            "In Progress"
        case .connected:
            "Success"
        case .failed:
            "Error"
        }
    }

    var detailText: String {
        switch self {
        case .notConnected:
            "No imported transaction data is stored yet."
        case .importing:
            "Import is currently running."
        case .connected(let importedCount):
            "Imported \(importedCount) transactions and stored them locally."
        case .failed(let message):
            message
        }
    }
}
