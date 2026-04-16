//
//  TransactionImportReviewSheet.swift
//  Bujet
//
//  Created by Zachary Beck on 15/04/2026.
//

import SwiftUI
import Observation

struct TransactionImportReviewSheet: View {
    let viewModel: HomeViewModel
    let onImportSuccess: () -> Void

    @State private var displayedRange: ImportDateRange
    @State private var session: TransactionImportSession
    
    init(viewModel: HomeViewModel, onImportSuccess: @escaping () -> Void) {
        guard
            let session = viewModel.pendingImportSession,
            let range = viewModel.selectedImportRange
        else {
            preconditionFailure("TransactionImportReviewSheet presented without import state")
        }

        self.viewModel = viewModel
        self.onImportSuccess = onImportSuccess
        _session = State(initialValue: session)
        _displayedRange = State(initialValue: range)
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        // These are guaranteed by presentation logic

        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Available range summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Import Window")
                        .font(.headline)

                    Text(
                        "\(session.availableRange.lowerBound.formatted(date: .abbreviated, time: .omitted)) – " +
                        "\(session.availableRange.upperBound.formatted(date: .abbreviated, time: .omitted))"
                    )
                    Text("\(viewModel.selectedImportPreviewCount) transactions in selected range")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Boundary selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select the range you want to import")
                        .font(.headline)

                    Text("Tap Start Date or End Date, then select a date.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        let selectedRange = displayedRange
                        RangeBoundaryCard(
                            title: "Start Date",
                            date: selectedRange.startDate,
                            isActive: viewModel.activeImportBoundary == .start
                        ) {
                            viewModel.setActiveImportBoundary(.start)
                        }

                        RangeBoundaryCard(
                            title: "End Date",
                            date: selectedRange.endDate,
                            isActive: viewModel.activeImportBoundary == .end
                        ) {
                            viewModel.setActiveImportBoundary(.end)
                        }
                    }
                }

                // MARK: - Calendar
                ImportRangeCalendarView(
                    selectedDate: Binding(
                        get: { viewModel.currentCalendarSelectionDate },
                        set: { viewModel.setCalendarSelectionDate($0) }
                    ),
                    availableRange: viewModel.selectableCalendarRange
                )
                .frame(height: 360)

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.importDismissReason = .cancel
                        viewModel.activeImportSheet = nil
                    }
                    .disabled(viewModel.isFinalisingImport)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.commitPendingImport(
                                onImportSuccess: onImportSuccess
                            )
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!viewModel.canCommitPendingImport)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isFinalisingImport)
        .onChange(of: viewModel.selectedImportRange) {
            if let newValue = viewModel.selectedImportRange {
                displayedRange = newValue
            }
        }
    }
}

private struct RangeBoundaryCard: View {
    let title: String
    let date: Date
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(isActive ? "Editing" : "Tap to edit")
                    .font(.caption)
                    .foregroundStyle(isActive ? .purple : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? Color.purple.opacity(0.12) : Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Color.purple : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
