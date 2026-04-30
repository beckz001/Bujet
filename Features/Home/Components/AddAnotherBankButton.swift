//
//  AddAnotherBankButton.swift
//  Bujet
//
//  Created by Zachary Beck on 30/04/2026.
//

import SwiftUI

struct AddAnotherBankButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                Text("Add another bank")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .surfaceTile(cornerRadius: 28)
        }
        .buttonStyle(.plain)
    }
}
