import Foundation

enum ManualTransactionValidationError: Error {
    case emptyEntry
    case invalidData
}

struct ManualTransactionValidator {
    static func validate(_ entry: ManualTransactionEntry, currencyCode: String) -> Result<Transaction, ManualTransactionValidationError> {
        let desc = entry.descriptionText.trimmingCharacters(in: .whitespaces)
        let merchant = entry.merchantName.trimmingCharacters(in: .whitespaces)
        let amountStr = entry.amountText.trimmingCharacters(in: .whitespaces)

        guard !desc.isEmpty, !merchant.isEmpty, !amountStr.isEmpty else {
            return .failure(.emptyEntry)
        }

        guard let amountValue = Double(amountStr), amountValue > 0 else {
            return .failure(.invalidData)
        }

        let signedAmount = entry.isCredit ? amountValue : -amountValue

        return .success(Transaction(
            id: UUID().uuidString,
            date: entry.date,
            description: desc,
            merchantName: merchant,
            amount: signedAmount,
            currencyCode: currencyCode,
            source: .manual,
            category: entry.category
        ))
    }
}
