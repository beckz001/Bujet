import SwiftUI

enum TransactionCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case bills
    case eatingOut = "eating_out"
    case groceries
    case transport
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bills:     "Bills"
        case .eatingOut: "Eating out"
        case .groceries: "Groceries"
        case .transport: "Transport"
        case .other:     "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .bills:     "list.bullet.rectangle.portrait"
        case .eatingOut: "fork.knife"
        case .groceries: "cart"
        case .transport: "car"
        case .other:     "square.grid.2x2"
        }
    }

    var color: Color {
        switch self {
        case .bills:     Color(hex: "004E89")
        case .eatingOut: Color(hex: "C7E84A")
        case .groceries: Color(hex: "F7C59F")
        case .transport: Color(hex: "FF6B35")
        case .other:     Color(hex: "9A7197")
        }
    }
}
