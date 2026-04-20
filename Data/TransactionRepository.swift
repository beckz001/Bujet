//
//  TransactionRepository.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

protocol TransactionRepository: Sendable {
    func fetchAll() async -> [Transaction]
    func replaceAll(with transactions: [Transaction]) async throws
    func add(_ transactions: [Transaction]) async throws
    func clear() async throws
}
