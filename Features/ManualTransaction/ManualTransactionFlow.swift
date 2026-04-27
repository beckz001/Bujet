import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class ManualTransactionFlow: Identifiable {
    let id = UUID()

    var entries: [ManualTransactionEntry] = [ManualTransactionEntry()]
    var isSubmitting = false
    var validationAlert: ValidationAlert?

    let currencyCode: String = Locale.current.currency?.identifier ?? "GBP"
    let maximumDate: Date = Calendar.current.startOfDay(for: .now)

    @ObservationIgnored private let transactionRepository: any TransactionRepository
    @ObservationIgnored private let onCommit: @MainActor (Int) -> Void
    @ObservationIgnored private let onCancel: @MainActor () -> Void
    @ObservationIgnored private let onFailed: @MainActor (Error) -> Void

    enum ValidationAlert: Identifiable {
        case emptyEntry
        case invalidData

        var id: String {
            switch self {
            case .emptyEntry: "emptyEntry"
            case .invalidData: "invalidData"
            }
        }

        var title: String { "Unable to Add" }

        var message: String {
            switch self {
            case .emptyEntry:
                "Transaction import not complete. Please fill in all fields and try again."
            case .invalidData:
                "Transaction data not valid. Please check the amount and try again."
            }
        }
    }

    init(
        transactionRepository: any TransactionRepository,
        onCommit: @escaping @MainActor (Int) -> Void,
        onCancel: @escaping @MainActor () -> Void,
        onFailed: @escaping @MainActor (Error) -> Void
    ) {
        self.transactionRepository = transactionRepository
        self.onCommit = onCommit
        self.onCancel = onCancel
        self.onFailed = onFailed
    }

    var hasUnsavedChanges: Bool {
        entries.contains {
            !$0.descriptionText.isEmpty || !$0.merchantName.isEmpty || !$0.amountText.isEmpty
        }
    }

    func addEntry() {
        withAnimation(.default) {
            entries.append(ManualTransactionEntry())
        }
    }

    func removeEntry(id: UUID) {
        withAnimation(.default) {
            entries.removeAll { $0.id == id }
            if entries.isEmpty {
                entries.append(ManualTransactionEntry())
            }
        }
    }

    func submit() async {
        guard !isSubmitting else { return }

        var transactions: [Transaction] = []
        for entry in entries {
            switch ManualTransactionValidator.validate(entry, currencyCode: currencyCode) {
            case .success(let t):
                transactions.append(t)
            case .failure(let error):
                validationAlert = error == .emptyEntry ? .emptyEntry : .invalidData
                return
            }
        }

        isSubmitting = true
        do {
            try await transactionRepository.add(transactions)
            isSubmitting = false
            onCommit(transactions.count)
        } catch {
            isSubmitting = false
            onFailed(error)
        }
    }

    func cancel() {
        guard !isSubmitting else { return }
        onCancel()
    }
    
    func binding(for entry: ManualTransactionEntry) -> Binding<ManualTransactionEntry> {
        Binding(
            get: { self.entries.first(where: { $0.id == entry.id}) ?? entry},
            set: { new in
                guard let i = self.entries.firstIndex(where: { $0.id == entry.id }) else { return }
                self.entries[i] = new
            }
        )
    }
}
