//
//  TrueLayerAPIError.swift
//  Bujet
//
//  Created by Zachary Beck on 09/04/2026.
//

import Foundation

struct TrueLayerAPIErrorModel: Decodable, Equatable {
    let error: String
    let errorDescription: String

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}

enum TrueLayerAPIErrorParser {
    static func parse(from error: Error) -> TrueLayerAPIErrorModel? {
        let raw = error.localizedDescription

        // Handle strings that may contain '+' instead of spaces
        let normalized = raw
            .replacingOccurrences(of: "+", with: " ")
            .removingPercentEncoding ?? raw.replacingOccurrences(of: "+", with: " ")

        guard let jsonStart = normalized.firstIndex(of: "{") else {
            return nil
        }

        let jsonString = String(normalized[jsonStart...])

        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(TrueLayerAPIErrorModel.self, from: data)
        } catch {
            #if DEBUG
            print("Failed to decode TrueLayer error payload: \(error)")
            print("Original string: \(normalized)")
            #endif
            return nil
        }
    }
}

extension String {
    var formattedErrorAlertTitle: String {
        self
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalizedSentence
    }

    private var capitalizedSentence: String {
        guard let first = self.first else { return self }
        return first.uppercased() + self.dropFirst()
    }
}
