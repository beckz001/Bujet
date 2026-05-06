import Foundation

/// Unified goal/pot model. A `Goal` is a "pot" when `linkedItem` is non-nil —
/// i.e. when the user is saving toward a specific wishlist purchase. Plain
/// goals (no linked item) are general savings targets like "Lisbon trip".
struct Goal: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var notes: String?
    var targetAmount: Double
    var savedAmount: Double
    var currencyCode: String
    var createdAt: Date
    var completedAt: Date?
    var linkedItem: WishlistItem?

    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        targetAmount: Double,
        savedAmount: Double = 0,
        currencyCode: String = "GBP",
        createdAt: Date = .now,
        completedAt: Date? = nil,
        linkedItem: WishlistItem? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
        self.currencyCode = currencyCode
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.linkedItem = linkedItem
    }

    var isPot: Bool { linkedItem != nil }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1.0, savedAmount / targetAmount)
    }

    var isComplete: Bool { savedAmount >= targetAmount }

    var remaining: Double { max(0, targetAmount - savedAmount) }
}
