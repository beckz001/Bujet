import Foundation

struct WishlistItem: Codable, Hashable {
    var itemName: String
    var estimatedCost: Double
    var category: TransactionCategory
    var currencyCode: String
    var createdFromIntervention: UUID?

    init(
        itemName: String,
        estimatedCost: Double,
        category: TransactionCategory,
        currencyCode: String = "GBP",
        createdFromIntervention: UUID? = nil
    ) {
        self.itemName = itemName
        self.estimatedCost = estimatedCost
        self.category = category
        self.currencyCode = currencyCode
        self.createdFromIntervention = createdFromIntervention
    }
}
