//
//  PhaseAInstructionsCard.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI

struct PhaseAInstructionsCard: View {
    var body: some View {
        Section("Phase A Workflow") {
            Text("1. Complete the TrueLayer Console preview flow.")
            Text("2. Copy the returned authentication code.")
            Text("3. Paste it into this screen.")
            Text("4. Import sample transactions into the local repository.")
        }
        .font(.body)
    }
}

