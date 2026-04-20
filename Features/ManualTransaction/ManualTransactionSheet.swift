import SwiftUI

struct ManualTransactionSheet: View {
    @Bindable var viewModel: ManualTransactionViewModel
    @State private var showCancelConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                        TransactionEntryCard(
                            entry: $viewModel.entries[index],
                            currencyCode: viewModel.currencyCode,
                            maximumDate: viewModel.maximumDate,
                            canRemove: viewModel.entries.count > 1,
                            onRemove: { viewModel.removeEntry(id: entry.id) }
                        )
                    }

                    Button {
                        viewModel.addEntry()
                    } label: {
                        Label("Add another transaction", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .disabled(viewModel.isSubmitting)
                }
                .padding()
            }
            .navigationTitle("Add Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.hasUnsavedChanges {
                            showCancelConfirmation = true
                        } else {
                            viewModel.cancel()
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Button {
                            Task { await viewModel.submit() }
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        .alert("Discard Changes?", isPresented: $showCancelConfirmation) {
            Button("Discard", role: .destructive) { viewModel.cancel() }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("Your transaction entries will be lost.")
        }
        .alert(item: $viewModel.validationAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .interactiveDismissDisabled(viewModel.isSubmitting || viewModel.hasUnsavedChanges)
    }
}

private struct TransactionEntryCard: View {
    @Binding var entry: ManualTransactionEntry
    let currencyCode: String
    let maximumDate: Date
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transaction")
                    .font(.headline)
                Spacer()
                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            DatePicker(
                "Date",
                selection: $entry.date,
                in: ...maximumDate,
                displayedComponents: .date
            )

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                TextField("Description", text: $entry.descriptionText)
                    .onChange(of: entry.descriptionText) { _, new in
                        if new.count > ManualTransactionEntry.maxDescriptionLength {
                            entry.descriptionText = String(new.prefix(ManualTransactionEntry.maxDescriptionLength))
                        }
                    }
                Text("\(entry.descriptionText.count)/\(ManualTransactionEntry.maxDescriptionLength)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                TextField("Merchant Name", text: $entry.merchantName)
                    .onChange(of: entry.merchantName) { _, new in
                        if new.count > ManualTransactionEntry.maxMerchantNameLength {
                            entry.merchantName = String(new.prefix(ManualTransactionEntry.maxMerchantNameLength))
                        }
                    }
                Text("\(entry.merchantName.count)/\(ManualTransactionEntry.maxMerchantNameLength)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider()

            HStack(spacing: 8) {
                Text(currencyCode)
                    .foregroundStyle(.secondary)
                    .font(.body)
                TextField("0.00", text: $entry.amountText)
                    .keyboardType(.decimalPad)
            }

            Divider()

            Toggle("Credit", isOn: $entry.isCredit)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
