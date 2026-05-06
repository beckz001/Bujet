import SwiftUI

struct PotContributionSheet: View {
    @Bindable var viewModel: PotContributionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.goal.name)
                        .font(.title3.weight(.semibold))
                    Text("Saved \(formatted(viewModel.goal.savedAmount)) of \(formatted(viewModel.goal.targetAmount))")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Text(viewModel.goal.currencyCode)
                        .foregroundStyle(.secondary)
                        .font(.title3)
                    TextField(
                        "0.00",
                        text: Binding(
                            get: { viewModel.amountText },
                            set: { viewModel.updateAmount($0) }
                        )
                    )
                    .font(.title3)
                    .keyboardType(.decimalPad)
                }
                .padding()
                .surfaceTile(cornerRadius: 16)

                Spacer()
            }
            .padding(20)
            .background(AppPalette.background.ignoresSafeArea())
            .navigationTitle("Add to pot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task {
                                if await viewModel.save() { dismiss() }
                            }
                        }
                        .disabled(!viewModel.canSave)
                    }
                }
            }
            .alert(
                "Couldn't add",
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

    private func formatted(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = viewModel.goal.currencyCode
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
