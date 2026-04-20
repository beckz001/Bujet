//
//  ImportOptionsViewModel.swift
//  Bujet
//
//  Created by Zachary Beck on 19/04/2026.
//

import Foundation
import Observation

/// Narrow façade over `TransactionImportFlow` exposing only what the
/// "import options" sheet needs to render and act on.
@MainActor
@Observable
final class ImportOptionsViewModel {
    @ObservationIgnored private let flow: TransactionImportFlow

    init(flow: TransactionImportFlow) {
        self.flow = flow
    }

    // MARK: - Read-only UI data

    var totalCount: Int {
        flow.session.totalCount
    }

    var availableRangeText: String {
        let range = flow.session.availableRange
        return "\(range.lowerBound.formatted(date: .abbreviated, time: .omitted)) – " +
               "\(range.upperBound.formatted(date: .abbreviated, time: .omitted))"
    }

    var isFinalising: Bool {
        flow.isFinalising
    }

    // MARK: - Actions

    func importAll() async {
        await flow.commitAll()
    }

    func chooseDateRange() {
        flow.chooseDateRange()
    }
}
