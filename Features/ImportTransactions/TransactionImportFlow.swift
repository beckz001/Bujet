//
//  TransactionImportFlow.swift
//  Bujet
//
//  Created by Zachary Beck on 19/04/2026.
//

import Foundation
import Observation

/// Owns every piece of state and behaviour for a single bank-import session
/// (session, selected range, active boundary, step navigation, finalisation).
/// HomeViewModel holds this optionally and is notified of outcomes via closures.
@MainActor
@Observable
final class TransactionImportFlow: Identifiable {
    let id = UUID()
    let session: TransactionImportSession

    var step: Step = .options
    var selectedRange: ImportDateRange
    var activeBoundary: ImportRangeBoundary = .start
    var isFinalising = false

    @ObservationIgnored private let transactionRepository: any TransactionRepository
    @ObservationIgnored private let onCommit: @MainActor (Int) -> Void
    @ObservationIgnored private let onCancel: @MainActor () -> Void
    @ObservationIgnored private let onFailed: @MainActor (Error) -> Void

    enum Step: String, Identifiable {
        case options
        case review
        var id: String { rawValue }
    }

    init(
        session: TransactionImportSession,
        transactionRepository: any TransactionRepository,
        onCommit: @escaping @MainActor (Int) -> Void,
        onCancel: @escaping @MainActor () -> Void,
        onFailed: @escaping @MainActor (Error) -> Void
    ) {
        self.session = session
        self.transactionRepository = transactionRepository
        self.onCommit = onCommit
        self.onCancel = onCancel
        self.onFailed = onFailed
        self.selectedRange = ImportDateRange(
            startDate: session.availableRange.lowerBound,
            endDate: session.availableRange.upperBound
        )
    }

    // MARK: - Derived UI state

    var previewCount: Int {
        session.previewCount(in: selectedRange)
    }

    var canCommit: Bool {
        selectedRange.startDate <= selectedRange.endDate
            && previewCount > 0
            && !isFinalising
    }

    var currentCalendarSelectionDate: Date {
        switch activeBoundary {
        case .start: selectedRange.startDate
        case .end:   selectedRange.endDate
        }
    }

    var selectableCalendarRange: ClosedRange<Date> {
        switch activeBoundary {
        case .start:
            session.availableRange.lowerBound...selectedRange.endDate
        case .end:
            selectedRange.startDate...session.availableRange.upperBound
        }
    }

    // MARK: - Navigation between steps

    func chooseDateRange() {
        step = .review
    }

    func returnToOptions() {
        step = .options
    }

    // MARK: - Boundary + calendar

    func setBoundary(_ boundary: ImportRangeBoundary) {
        activeBoundary = boundary
    }

    func setDate(_ date: Date) {
        let normalised = session.calendar.startOfDay(for: date)

        switch activeBoundary {
        case .start:
            guard normalised <= selectedRange.endDate else { return }
            selectedRange.startDate = normalised

        case .end:
            guard normalised >= selectedRange.startDate else { return }
            selectedRange.endDate = normalised
        }
    }

    // MARK: - Terminal actions

    /// Commit the full available range, bypassing the review step.
    func commitAll() async {
        selectedRange = ImportDateRange(
            startDate: session.availableRange.lowerBound,
            endDate: session.availableRange.upperBound
        )
        await commit()
    }

    /// Commit the currently selected range.
    func commit() async {
        guard !isFinalising else { return }
        isFinalising = true

        let filtered = session.filteredTransactions(in: selectedRange)

        do {
            try await transactionRepository.replaceAll(with: filtered)
            isFinalising = false
            onCommit(filtered.count)
        } catch {
            isFinalising = false
            onFailed(error)
        }
    }

    func cancel() {
        guard !isFinalising else { return }
        onCancel()
    }
}
