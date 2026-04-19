//
//  ImportFlowContainer.swift
//  Bujet
//
//  Created by Zachary Beck on 19/04/2026.
//

import SwiftUI

/// Hosts the two import sheets (options / review) inside a single presentation.
/// The outer sheet stays up for the whole flow — switching between steps is
/// an internal view swap driven by `flow.step`, which avoids dismiss/re-present
/// bookkeeping in `HomeView`.
struct ImportFlowContainer: View {
    let flow: TransactionImportFlow

    @State private var optionsViewModel: ImportOptionsViewModel
    @State private var reviewViewModel: ImportReviewViewModel

    init(flow: TransactionImportFlow) {
        self.flow = flow
        _optionsViewModel = State(wrappedValue: ImportOptionsViewModel(flow: flow))
        _reviewViewModel = State(wrappedValue: ImportReviewViewModel(flow: flow))
    }

    var body: some View {
        switch flow.step {
        case .options:
            TransactionImportOptionsSheet(viewModel: optionsViewModel)
        case .review:
            TransactionImportReviewSheet(viewModel: reviewViewModel)
        }
    }
}
