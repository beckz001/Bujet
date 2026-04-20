//
//  ImportReviewViewModel.swift
//  Bujet
//
//  Created by Zachary Beck on 19/04/2026.
//

import Foundation
import Observation

/// Narrow façade over `TransactionImportFlow` exposing only what the
/// "import review" sheet (calendar + boundary cards) needs.
@MainActor
@Observable
final class ImportReviewViewModel {
    @ObservationIgnored private let flow: TransactionImportFlow

    init(flow: TransactionImportFlow) {
        self.flow = flow
    }

    // MARK: - Read-only UI data

    var availableRange: ClosedRange<Date> {
        flow.session.availableRange
    }

    var selectedRange: ImportDateRange {
        flow.selectedRange
    }

    var activeBoundary: ImportRangeBoundary {
        flow.activeBoundary
    }

    var previewCount: Int {
        flow.previewCount
    }

    var canCommit: Bool {
        flow.canCommit
    }

    var isFinalising: Bool {
        flow.isFinalising
    }

    var selectableCalendarRange: ClosedRange<Date> {
        flow.selectableCalendarRange
    }

    /// Settable binding source for `ImportRangeCalendarView`. Reads the
    /// currently-editing boundary's date; writes delegate back to the flow.
    var calendarDate: Date {
        get { flow.currentCalendarSelectionDate }
        set { flow.setDate(newValue) }
    }

    // MARK: - Actions

    func setBoundary(_ boundary: ImportRangeBoundary) {
        flow.setBoundary(boundary)
    }

    func setDate(_ date: Date) {
        flow.setDate(date)
    }

    func commit() async {
        await flow.commit()
    }

    func cancel() {
        flow.cancel()
    }

    func returnToOptions() {
        flow.returnToOptions()
    }
}
