//
//  PhaseAInstructionsCard.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//

import SwiftUI

struct ImportInstructionsCard: View {
    var body: some View {
        Section("Import Workflow") {
            Text("1. Complete the TrueLayer sandbox preview flow in the browser.")
            Text("2. Copy the returned authentication code.")
            Text("3. Paste the code into this screen.")
            Text("4. The app sends the code to your backend.")
            Text("5. The backend exchanges the code and imports real sandbox transactions.")
        }
        .font(.body)
    }
}

