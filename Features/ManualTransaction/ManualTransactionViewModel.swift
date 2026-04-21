import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ManualTransactionViewModel {
    @ObservationIgnored private let flow: ManualTransactionFlow

    init(flow: ManualTransactionFlow) {
        self.flow = flow
    }

    var entries: [ManualTransactionEntry] {
        get { flow.entries }
        set { flow.entries = newValue }
    }

    var isSubmitting: Bool { flow.isSubmitting }

    var validationAlert: ManualTransactionFlow.ValidationAlert? {
        get { flow.validationAlert }
        set { flow.validationAlert = newValue }
    }

    var currencyCode: String { flow.currencyCode }
    var maximumDate: Date { flow.maximumDate }
    var hasUnsavedChanges: Bool { flow.hasUnsavedChanges }

    func addEntry() { flow.addEntry() }
    func removeEntry(id: UUID) { flow.removeEntry(id: id) }
    func submit() async { await flow.submit() }
    func cancel() { flow.cancel() }
    
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
