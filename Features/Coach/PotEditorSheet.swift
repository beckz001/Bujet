import SwiftUI

struct PotEditorSheet: View {
    @Bindable var viewModel: PotEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pots are little buckets you save toward — anything from a Lisbon trip to a pair of trainers you're trying not to impulse-buy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Pot name", text: $viewModel.name)
                            .textInputAutocapitalization(.sentences)

                        Divider()

                        HStack(spacing: 8) {
                            Text(viewModel.currencyCode)
                                .foregroundStyle(.secondary)
                            TextField(
                                "Target amount",
                                text: Binding(
                                    get: { viewModel.targetAmountText },
                                    set: { viewModel.updateAmount($0) }
                                )
                            )
                            .keyboardType(.decimalPad)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("What are you saving for?")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            TextField(
                                "e.g. Long weekend in Lisbon",
                                text: $viewModel.notesText,
                                axis: .vertical
                            )
                            .textInputAutocapitalization(.sentences)
                            .lineLimit(2...4)
                        }
                    }
                    .padding()
                    .surfaceTile(cornerRadius: 20)
                }
                .padding(20)
            }
            .background(AppPalette.background.ignoresSafeArea())
            .navigationTitle("New Pot")
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
                        Button("Create") {
                            Task {
                                if await viewModel.save() {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.canSave)
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
    }
}
