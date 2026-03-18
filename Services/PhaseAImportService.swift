//
//  PhaseAImportService.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

protocol PhaseAImportService: Sendable {
    func importTransactions(using authCode: String) async throws -> [Transaction]
}
