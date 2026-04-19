//
//  TrueLayerAuthService.swift
//  Bujet
//
//  Created by Zachary Beck on 19/03/2026.
//

import Foundation
import SwiftUI
import AuthenticationServices

@MainActor
final class TrueLayerAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func authenticate(authURL: URL) async throws -> URL {
        defer { session = nil }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "bujet"
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: AuthFlowError.missingCallbackURL)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            session.start()
        }
    }


    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            preconditionFailure("No active UIWindowScene available for ASWebAuthenticationSession.")
        }

        return windowScene.keyWindow
            ?? windowScene.windows.first(where: \.isKeyWindow)
            ?? windowScene.windows.first
            ?? UIWindow(windowScene: windowScene)
    }

}

enum AuthFlowError: LocalizedError {
    case missingCallbackURL
    case invalidCallback

    var errorDescription: String? {
        switch self {
        case .missingCallbackURL:
            "The authentication flow did not return a callback URL."
        case .invalidCallback:
            "The callback URL was invalid."
        }
    }
}
