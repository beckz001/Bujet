import SwiftUI

struct PauseReflectInputView: View {
    @Bindable var flow: PreSpendInterventionFlow

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Tell us what you're considering. We'll show how it lands against your spending and budgets — no judgement.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    amountField
                    Divider()
                    descriptionField
                    Divider()
                    categoryPicker
                }
                .padding()
                .surfaceTile(cornerRadius: 20)

                if let inputError = flow.inputErrorMessage {
                    Label(inputError, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let evalError = flow.evaluationErrorMessage {
                    Label(evalError, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await flow.submitInput() }
                } label: {
                    HStack {
                        if flow.isEvaluating {
                            ProgressView().tint(.white)
                        } else {
                            Text("Reflect")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!flow.canSubmitInput)
            }
            .padding(20)
        }
    }

    private var amountField: some View {
        HStack(spacing: 8) {
            Text(flow.currencyCode)
                .foregroundStyle(.secondary)
                .font(.title3)
            TextField("0.00", text: $flow.amountText)
                .font(.title3)
                .keyboardType(.decimalPad)
                .onChange(of: flow.amountText) { _, new in
                    flow.amountText = new.sanitisedAmount
                }
        }
    }

    private var descriptionField: some View {
        TextField("What is it? e.g. Nike trainers", text: $flow.itemDescription)
            .textInputAutocapitalization(.sentences)
    }

    private var categoryPicker: some View {
        Picker(selection: $flow.category) {
            ForEach(TransactionCategory.allCases) { category in
                Label(category.displayName, systemImage: category.systemImage)
                    .tag(category)
            }
        } label: {
            Text("Category")
        }
        .pickerStyle(.menu)
    }
}
