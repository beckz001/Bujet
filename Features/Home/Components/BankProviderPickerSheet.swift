//
//  BankProviderPickerSheet.swift
//  Bujet
//
//  Created by Zachary Beck on 30/04/2026.
//

import SwiftUI

struct BankProviderPickerSheet: View {
    let providers: [BankProvider]
    let connectedProviderIDs: Set<String>
    let onSelect: (BankProvider) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(providers) { provider in
                        Button {
                            onSelect(provider)
                        } label: {
                            ProviderRow(
                                provider: provider,
                                isAlreadyConnected: connectedProviderIDs.contains(provider.id)
                            )
                        }
                        .disabled(connectedProviderIDs.contains(provider.id))
                    }
                } footer: {
                    Text("Connect a sandbox bank to import its transactions. Each bank can be connected once.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select a Bank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

private struct ProviderRow: View {
    let provider: BankProvider
    let isAlreadyConnected: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(provider.tint.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: provider.iconSystemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(provider.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(provider.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                if isAlreadyConnected {
                    Text("Already connected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !isAlreadyConnected {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }
}
