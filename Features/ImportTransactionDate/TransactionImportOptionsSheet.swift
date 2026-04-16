//
//  TransactionImportOptionsSheet.swift
//  Bujet
//
//  Created by Zachary Beck on 15/04/2026.
//

import SwiftUI

struct TransactionImportOptionsSheet: View {
    let viewModel: HomeViewModel
    let onImportSuccess: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if let session = viewModel.pendingImportSession {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Imported Transactions Ready")
                            .font(.title2.bold())

                        Text("\(session.totalCount) transactions were found.")
                            .font(.body)

                        Text(
                            "Available dates: \(session.availableRange.lowerBound.formatted(date: .abbreviated, time: .omitted)) – \(session.availableRange.upperBound.formatted(date: .abbreviated, time: .omitted))"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 16) {
                    Button {
                        Task {
                            await viewModel.commitFullPendingImport(onImportSuccess: onImportSuccess)
                        }
                    } label: {
                        Label("Import All Transactions", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel.isFinalisingImport)

                    Button {
                        viewModel.showImportRangeSheet()
                    } label: {
                        Label("Choose Date Range", systemImage: "calendar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .disabled(viewModel.isFinalisingImport)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Import Options")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isFinalisingImport)
    }
}
