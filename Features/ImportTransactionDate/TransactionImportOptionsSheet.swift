//
//  TransactionImportOptionsSheet.swift
//  Bujet
//
//  Created by Zachary Beck on 15/04/2026.
//

import SwiftUI

struct TransactionImportOptionsSheet: View {
    let viewModel: ImportOptionsViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Imported Transactions Ready")
                        .font(.title2.bold())

                    Text("\(viewModel.totalCount) transactions were found.")
                        .font(.body)

                    Text("Available dates: \(viewModel.availableRangeText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    Button {
                        Task { await viewModel.importAll() }
                    } label: {
                        Label("Import All Transactions", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel.isFinalising)

                    Button {
                        viewModel.chooseDateRange()
                    } label: {
                        Label("Choose Date Range", systemImage: "calendar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .disabled(viewModel.isFinalising)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Import Options")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isFinalising)
    }
}
