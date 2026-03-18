//
//  TransactionRowView.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(transaction.merchantName)
                .font(.headline)

            Text(transaction.description)
                .font(.body)
                .foregroundStyle(.secondary)

            HStack {
                Text(transaction.bookedAt, format: .dateTime.day().month().year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(transaction.amount, format: .currency(code: transaction.currencyCode))
                    .font(.body.bold())
                    .foregroundStyle(transaction.isDebit ? .red : .green)
            }
        }
        .padding(.vertical, 4)
    }
}
