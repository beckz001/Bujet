import SwiftUI

struct BudgetsSheet: View {
    @Bindable var viewModel: BudgetsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Set a monthly cap for any category. Leave blank to skip.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        ForEach(TransactionCategory.allCases) { category in
                            BudgetRow(
                                category: category,
                                currencyCode: viewModel.currencyCode,
                                amountText: Binding(
                                    get: { viewModel.binding(for: category) },
                                    set: { viewModel.update($0, for: category) }
                                )
                            )
                        }
                    }

                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear all", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!viewModel.hasAnyValue || viewModel.isSaving)
                    .padding(.top, 4)
                }
                .padding()
            }
            .confirmationDialog(
                "Clear all budgets?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear all", role: .destructive) {
                    viewModel.clearAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Tap Save afterwards to apply.")
            }
            .background(AppPalette.background.ignoresSafeArea())
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                if await viewModel.save() {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .alert(
                "Couldn't save",
                isPresented: Binding(
                    get: { viewModel.validationMessage != nil },
                    set: { if !$0 { viewModel.validationMessage = nil } }
                ),
                presenting: viewModel.validationMessage
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
        .task { await viewModel.load() }
    }
}

private struct BudgetRow: View {
    let category: TransactionCategory
    let currencyCode: String
    @Binding var amountText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.body)
                .frame(width: 32, height: 32)
                .background(category.color.opacity(0.2), in: Circle())
                .foregroundStyle(category.color)

            Text(category.displayName)
                .font(.body)

            Spacer()

            HStack(spacing: 4) {
                Text(currencyCode)
                    .foregroundStyle(.secondary)
                    .font(.body)
                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 80)
            }
        }
        .padding(16)
        .surfaceTile(cornerRadius: 16)
    }
}
