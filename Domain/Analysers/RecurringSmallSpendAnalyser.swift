import Foundation

/// Surfaces merchants the user has bought from repeatedly this week with
/// individually small charges — the classic "death by a thousand cuts"
/// pattern (corner-shop runs, café trips, takeaway micro-transactions).
struct RecurringSmallSpendAnalyser: InsightAnalyser {
    /// Minimum number of separate charges with the same merchant in the week
    /// before we'll flag it.
    private let minimumOccurrences: Int = 3
    /// Per-charge ceiling — above this and it isn't really "small".
    private let perChargeCeiling: Double = 12
    /// Minimum total spend on a single merchant before flagging — avoids
    /// raising "3 × £1.20 vending machine" as a notable insight.
    private let minimumTotal: Double = 15

    func analyse(facts: WeeklyFacts) -> [InsightCandidate] {
        let buckets = bucketByMerchant(facts.weekTransactions)
        var out: [InsightCandidate] = []
        for charges in buckets.values {
            guard charges.count >= minimumOccurrences else { continue }
            let total = charges.reduce(0) { $0 + abs($1.amount) }
            let mean = total / Double(charges.count)
            guard mean <= perChargeCeiling, total >= minimumTotal else { continue }

            let display = displayName(for: charges)
            let category = mostCommonCategory(charges)
            let formatter = currencyFormatter(currencyCode: facts.currencyCode)
            let formattedTotal = formatter.string(from: NSNumber(value: total)) ?? "\(total)"
            let formattedMean = formatter.string(from: NSNumber(value: mean)) ?? "\(mean)"

            out.append(InsightCandidate(
                kind: .recurringSmall,
                category: category,
                merchantHint: display,
                primaryAmount: total,
                comparisonAmount: mean,
                occurrenceCount: charges.count,
                currencyCode: facts.currencyCode,
                severity: min(1, total / 60),
                headline: "\(charges.count)× \(display) this week",
                templateNarrative: "\(charges.count) trips to \(display) added up to \(formattedTotal) this week — averaging \(formattedMean) a time. Small charges are easy to miss; worth seeing the running total in one place."
            ))
        }
        return out
    }

    private func bucketByMerchant(_ txs: [Transaction]) -> [String: [Transaction]] {
        var buckets: [String: [Transaction]] = [:]
        for tx in txs where tx.isDebit {
            let key = tx.merchantName
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            buckets[key, default: []].append(tx)
        }
        return buckets
    }

    /// Pick the merchant name spelling that appears most often — preserves
    /// the user's actual casing for display.
    private func displayName(for charges: [Transaction]) -> String {
        let counts = Dictionary(charges.map { ($0.merchantName, 1) }, uniquingKeysWith: +)
        return counts.max(by: { $0.value < $1.value })?.key ?? charges[0].merchantName
    }

    private func mostCommonCategory(_ charges: [Transaction]) -> TransactionCategory {
        let counts = Dictionary(charges.map { ($0.category, 1) }, uniquingKeysWith: +)
        return counts.max(by: { $0.value < $1.value })?.key ?? .other
    }

    private func currencyFormatter(currencyCode: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 2
        return f
    }
}
