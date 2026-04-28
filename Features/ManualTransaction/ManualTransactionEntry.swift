import Foundation

struct ManualTransactionEntry: Identifiable {
    let id = UUID()
    var date: Date = Calendar.current.startOfDay(for: .now)
    var descriptionText: String = ""
    var merchantName: String = ""
    var amountText: String = ""
    var isCredit: Bool = false
    var category: TransactionCategory = .other

    static let maxDescriptionLength = 20
    static let maxMerchantNameLength = 150
}
