//
//  ImportError.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

enum ImportError: LocalizedError {
    case missingFixtureFile
    case invalidFixtureData
    case emptyCode

    var errorDescription: String? {
        switch self {
        case .missingFixtureFile:
            "The sample transactions file could not be found in the app bundle."
        case .invalidFixtureData:
            "The sample transactions file could not be decoded."
        case .emptyCode:
            "The authentication code is empty."
        }
    }
}
