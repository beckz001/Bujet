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

enum TrueLayerAuthError: LocalizedError {
    case apiError(TrueLayerAPIErrorModel)

    var errorDescription: String? {
        switch self {
        case .apiError(let model):
            model.errorDescription
        }
    }
}

enum TrueLayerAPIErrorParser {
    static func parse(from error: Error) -> TrueLayerAPIErrorModel? {
        if case let TrueLayerAuthError.apiError(model) = error {
            return model
        }
        return parse(jsonString: error.localizedDescription)
    }

    /// Inspect callback query items for either a TrueLayer-style `message`
    /// payload (URL-encoded JSON) or OAuth-standard `error` / `error_description`.
    static func parse(queryItems: [URLQueryItem]) -> TrueLayerAPIErrorModel? {
        func value(_ name: String) -> String? {
            queryItems.first(where: { $0.name == name })?.value
        }

        if let message = value("message"), let model = parse(jsonString: message) {
            return model
        }

        if let errorCode = value("error") {
            return TrueLayerAPIErrorModel(
                error: errorCode,
                errorDescription: value("error_description") ?? errorCode
            )
        }

        return nil
    }

    static func parse(jsonString raw: String) -> TrueLayerAPIErrorModel? {
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
