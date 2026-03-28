////
////  ConnectionStatusCard.swift
////  Bujet
////
////  Created by Zachary Beck on 18/03/2026.
////
//
//import SwiftUI
//
//struct ConnectionStatusCard: View {
//    let connectionState: BankConnectionState
//
//    var body: some View {
//        Section("Connection Status") {
//            LabeledContent {
//                Label(connectionState.title, systemImage: connectionState.systemImage)
//                    .foregroundStyle(symbolTint)
//            } label: {
//                Text("State")
//            }
//
//            LabeledContent("Details") {
//                Text(connectionState.detailText)
//                    .foregroundStyle(.secondary)
//                    .multilineTextAlignment(.trailing)
//            }
//        }
//    }
//
//    private var symbolTint: Color {
//        switch connectionState {
//        case .notConnected:
//            .secondary
//        case .importing:
//            .orange
//        case .connected:
//            .green
//        case .failed:
//            .red
//        }
//    }
//}
