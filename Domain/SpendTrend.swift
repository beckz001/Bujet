import Foundation

/// Spend-aware trend. For a budgeting app, "down" is the favourable direction
/// (you spent less than the comparable window last month).
enum SpendTrend: Equatable {
    case up(percentage: Double)
    case down(percentage: Double)
    case flat
}
