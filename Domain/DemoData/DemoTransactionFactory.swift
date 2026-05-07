import Foundation

/// Builds a believable 8-week transaction history for demo purposes. The
/// dataset is hand-tuned (not randomised) so the demo always tells the same
/// story:
///
/// - A weekly groove of groceries, transport, and small daily spends.
/// - Recurring sub-£5 charges at one café (Pret A Manger) several times per
///   week — designed to trip `RecurringSmallSpendAnalyser`.
/// - A clear shopping spike in the most recent week — designed to trip
///   `OverspendAnalyser` against the prior 7-week baseline.
/// - Monthly salary credits and the usual subscription debits so totals look
///   like a real account.
///
/// Generated transactions are tagged with the *demo provider's local ID* by
/// the connector, just like real TrueLayer imports, so they slot into the
/// existing review sheet and connection state machine unchanged.
enum DemoTransactionFactory {
    static let providerID = "demo-data"

    /// Number of weeks of history (current week + 7 prior weeks).
    private static let totalWeeks = 8

    static func makeTransactions(now: Date = .now, calendar: Calendar = .current) -> [Transaction] {
        var output: [Transaction] = []
        let today = calendar.startOfDay(for: now)

        for weekOffset in 0..<totalWeeks {
            output.append(contentsOf: weekTransactions(
                weekOffset: weekOffset,
                today: today,
                calendar: calendar
            ))
        }

        output.append(contentsOf: monthlyTransactions(
            today: today,
            calendar: calendar
        ))

        return output.sorted { $0.date > $1.date }
    }

    // MARK: - Weekly cadence

    private static func weekTransactions(
        weekOffset: Int,
        today: Date,
        calendar: Calendar
    ) -> [Transaction] {
        // weekOffset 0 = the past 7 days (current week)
        let dayOffsetBase = -7 * weekOffset
        let isCurrentWeek = weekOffset == 0
        var txs: [Transaction] = []

        // Pret — 4 weekday mornings (Mon, Tue, Wed, Thu).
        let pretAmounts = [-3.95, -4.20, -3.85, -4.10]
        for (i, amount) in pretAmounts.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: dayOffsetBase - (1 + i), to: today),
                  date <= today
            else { continue }
            txs.append(Self.tx(
                idStem: "pret-w\(weekOffset)-d\(i)",
                date: date,
                description: "PRET A MANGER",
                merchantName: "Pret A Manger",
                amount: amount,
                category: .eatingOut
            ))
        }

        // Big weekly grocery shop — Saturday-ish.
        if let date = calendar.date(byAdding: .day, value: dayOffsetBase - 5, to: today),
           date <= today {
            let amount = -[58.40, 47.20, 62.10, 51.30, 49.85, 68.20, 54.65, 60.10][weekOffset % 8]
            txs.append(Self.tx(
                idStem: "tesco-w\(weekOffset)",
                date: date,
                description: "TESCO STORES 4421",
                merchantName: "Tesco",
                amount: amount,
                category: .groceries
            ))
        }

        // Top-up grocery — Wednesday-ish.
        if let date = calendar.date(byAdding: .day, value: dayOffsetBase - 2, to: today),
           date <= today {
            let amount = -[12.40, 9.85, 14.20, 8.50, 11.10, 13.75, 10.25, 9.40][weekOffset % 8]
            txs.append(Self.tx(
                idStem: "sainsbury-w\(weekOffset)",
                date: date,
                description: "SAINSBURYS LOCAL",
                merchantName: "Sainsbury's Local",
                amount: amount,
                category: .groceries
            ))
        }

        // TfL weekly cap — Sunday rolls up.
        if let date = calendar.date(byAdding: .day, value: dayOffsetBase, to: today),
           date <= today {
            txs.append(Self.tx(
                idStem: "tfl-w\(weekOffset)",
                date: date,
                description: "TFL TRAVEL CH",
                merchantName: "Transport for London",
                amount: -38.40,
                category: .transport
            ))
        }

        // Eating out — Friday night, varies.
        let fridayPicks: [(String, Double, TransactionCategory)] = [
            ("Dishoom", -42.60, .eatingOut),
            ("Honest Burgers", -28.50, .eatingOut),
            ("Wagamama", -31.20, .eatingOut),
            ("Franco Manca", -24.80, .eatingOut),
            ("Nando's", -22.40, .eatingOut),
            ("Pho", -26.10, .eatingOut),
            ("Pizza Express", -29.40, .eatingOut),
            ("Bao", -34.20, .eatingOut),
        ]
        if let date = calendar.date(byAdding: .day, value: dayOffsetBase - 4, to: today),
           date <= today {
            let pick = fridayPicks[weekOffset % fridayPicks.count]
            txs.append(Self.tx(
                idStem: "fri-meal-w\(weekOffset)",
                date: date,
                description: pick.0.uppercased(),
                merchantName: pick.0,
                amount: pick.1,
                category: pick.2
            ))
        }

        // The current week's shopping spike — designed to trip overspend.
        if isCurrentWeek {
            let spikeItems: [(String, Double)] = [
                ("ASOS", -86.50),
                ("Uniqlo", -64.90),
                ("JD Sports", -54.00),
                ("Amazon UK", -32.40),
            ]
            for (i, item) in spikeItems.enumerated() {
                guard let date = calendar.date(byAdding: .day, value: -(2 + i), to: today),
                      date <= today
                else { continue }
                txs.append(Self.tx(
                    idStem: "shop-spike-\(i)",
                    date: date,
                    description: item.0.uppercased(),
                    merchantName: item.0,
                    amount: item.1,
                    category: .shopping
                ))
            }
        } else if weekOffset == 4 {
            // One small earlier shopping purchase so baseline isn't literally zero.
            if let date = calendar.date(byAdding: .day, value: dayOffsetBase - 3, to: today) {
                txs.append(Self.tx(
                    idStem: "shop-baseline",
                    date: date,
                    description: "UNIQLO",
                    merchantName: "Uniqlo",
                    amount: -28.50,
                    category: .shopping
                ))
            }
        }

        // Random Uber once per week — transport variance.
        if weekOffset % 2 == 0,
           let date = calendar.date(byAdding: .day, value: dayOffsetBase - 6, to: today),
           date <= today {
            txs.append(Self.tx(
                idStem: "uber-w\(weekOffset)",
                date: date,
                description: "UBER *TRIP",
                merchantName: "Uber",
                amount: -[12.50, 18.20, 9.80, 14.40][weekOffset % 4],
                category: .transport
            ))
        }

        return txs
    }

    // MARK: - Monthly cadence (salary, subscriptions)

    private static func monthlyTransactions(
        today: Date,
        calendar: Calendar
    ) -> [Transaction] {
        var txs: [Transaction] = []
        // Cover the past 3 calendar months including the current one.
        for monthOffset in 0...2 {
            guard let monthAnchor = calendar.date(byAdding: .month, value: -monthOffset, to: today)
            else { continue }
            let comps = calendar.dateComponents([.year, .month], from: monthAnchor)

            // Salary — 25th.
            if let salaryDate = calendar.date(from: DateComponents(
                year: comps.year, month: comps.month, day: 25
            )), salaryDate <= today {
                txs.append(Self.tx(
                    idStem: "salary-\(comps.year ?? 0)-\(comps.month ?? 0)",
                    date: salaryDate,
                    description: "SALARY ACME LTD",
                    merchantName: "Acme Ltd",
                    amount: 2400,
                    category: .other
                ))
            }

            // Netflix — 5th.
            if let date = calendar.date(from: DateComponents(
                year: comps.year, month: comps.month, day: 5
            )), date <= today {
                txs.append(Self.tx(
                    idStem: "netflix-\(comps.year ?? 0)-\(comps.month ?? 0)",
                    date: date,
                    description: "NETFLIX.COM",
                    merchantName: "Netflix",
                    amount: -15.99,
                    category: .bills
                ))
            }

            // Spotify — 12th.
            if let date = calendar.date(from: DateComponents(
                year: comps.year, month: comps.month, day: 12
            )), date <= today {
                txs.append(Self.tx(
                    idStem: "spotify-\(comps.year ?? 0)-\(comps.month ?? 0)",
                    date: date,
                    description: "SPOTIFY",
                    merchantName: "Spotify",
                    amount: -10.99,
                    category: .bills
                ))
            }

            // Phone bill — 18th.
            if let date = calendar.date(from: DateComponents(
                year: comps.year, month: comps.month, day: 18
            )), date <= today {
                txs.append(Self.tx(
                    idStem: "ee-\(comps.year ?? 0)-\(comps.month ?? 0)",
                    date: date,
                    description: "EE LIMITED",
                    merchantName: "EE",
                    amount: -25,
                    category: .bills
                ))
            }

            // Energy — 1st.
            if let date = calendar.date(from: DateComponents(
                year: comps.year, month: comps.month, day: 1
            )), date <= today {
                txs.append(Self.tx(
                    idStem: "octopus-\(comps.year ?? 0)-\(comps.month ?? 0)",
                    date: date,
                    description: "OCTOPUS ENERGY",
                    merchantName: "Octopus Energy",
                    amount: -78.40,
                    category: .bills
                ))
            }

            // Rent — 28th.
            if let date = calendar.date(from: DateComponents(
                year: comps.year, month: comps.month, day: 28
            )), date <= today {
                txs.append(Self.tx(
                    idStem: "rent-\(comps.year ?? 0)-\(comps.month ?? 0)",
                    date: date,
                    description: "RENT TFR",
                    merchantName: "Landlord",
                    amount: -950,
                    category: .bills
                ))
            }
        }
        return txs
    }

    private static func tx(
        idStem: String,
        date: Date,
        description: String,
        merchantName: String,
        amount: Double,
        category: TransactionCategory
    ) -> Transaction {
        Transaction(
            id: "demo-\(idStem)",
            date: date,
            description: description,
            merchantName: merchantName,
            amount: amount,
            currencyCode: "GBP",
            source: .imported,
            category: category
        )
    }
}
