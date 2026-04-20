//
//  TransactionImportReviewSheet.swift
//  Bujet
//
//  Created by Zachary Beck on 15/04/2026.
//

import SwiftUI

struct TransactionImportReviewSheet: View {
    @Bindable var viewModel: ImportReviewViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Available range summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Import Window")
                        .font(.headline)

                    Text(
                        "\(viewModel.availableRange.lowerBound.formatted(date: .abbreviated, time: .omitted)) – " +
                        "\(viewModel.availableRange.upperBound.formatted(date: .abbreviated, time: .omitted))"
                    )
                    Text("\(viewModel.previewCount) transactions in selected range")
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
                        RangeBoundaryCard(
                            title: "Start Date",
                            date: viewModel.selectedRange.startDate,
                            isActive: viewModel.activeBoundary == .start
                        ) {
                            viewModel.setBoundary(.start)
                        }

                        RangeBoundaryCard(
                            title: "End Date",
                            date: viewModel.selectedRange.endDate,
                            isActive: viewModel.activeBoundary == .end
                        ) {
                            viewModel.setBoundary(.end)
                        }
                    }
                }

                // MARK: - Calendar
                ImportRangeCalendarView(
                    selectedDate: $viewModel.calendarDate,
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
                        viewModel.cancel()
                    }
                    .disabled(viewModel.isFinalising)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.commit() }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!viewModel.canCommit)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isFinalising)
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
