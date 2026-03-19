//
//  PhaseAInstructionsCard.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI

struct ImportInstructionsCard: View {
    var body: some View {
        Section("Workflow") {
            Text("1. Tap Import Transactions.")
            Text("2. Complete the TrueLayer sandbox login flow.")
            Text("3. The backend exchanges the code and imports transactions.")
            Text("4. The app returns and shows the imported results.")
        }
        .font(.body)
    }
}
