import SwiftUI

struct ManualTransactionSheet: View {
    @Bindable var flow: ManualTransactionFlow
    @State private var showCancelConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(flow.entries) { entry in
                        TransactionEntryCard(
                            entry: flow.binding(for: entry),
                            currencyCode: flow.currencyCode,
                            maximumDate: flow.maximumDate,
                            canRemove: flow.entries.count > 1,
                            onRemove: { flow.removeEntry(id: entry.id) }
                        )
                    }

                    Button {
                        flow.addEntry()
                    } label: {
                        Label("Add another transaction", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .disabled(flow.isSubmitting)
                }
                .padding()
            }
            .navigationTitle("Add Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if flow.hasUnsavedChanges {
                            showCancelConfirmation = true
                        } else {
                            flow.cancel()
                        }
                    }
                    .disabled(flow.isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if flow.isSubmitting {
                        ProgressView()
                    } else {
                        Button {
                            Task { await flow.submit() }
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        .alert("Discard Changes?", isPresented: $showCancelConfirmation) {
            Button("Discard", role: .destructive) { flow.cancel() }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("Your transaction entries will be lost.")
        }
        .alert(item: $flow.validationAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .interactiveDismissDisabled(flow.isSubmitting || flow.hasUnsavedChanges)
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
                        let sanitised = new
                            .alphanumericWithSpacesOnly
                            .prefix(ManualTransactionEntry.maxDescriptionLength)
                        entry.descriptionText = String(sanitised)
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
                        let sanitised = new
                            .alphanumericWithSpacesOnly
                            .prefix(ManualTransactionEntry.maxMerchantNameLength)
                        entry.merchantName = String(sanitised)
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
                    .onChange(of: entry.amountText) { _, new in
                        entry.amountText = new.sanitisedAmount
                    }
            }

            Divider()

            Toggle("Credit", isOn: $entry.isCredit)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
