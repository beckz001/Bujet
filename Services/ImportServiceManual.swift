//
//  PhaseAImportService.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

protocol ImportServiceManual: Sendable {
    func importTransactionsManually(using authCode: String) async throws -> [Transaction]
}
