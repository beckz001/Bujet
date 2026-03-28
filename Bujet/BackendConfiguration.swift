//
//  BackendConfiguration.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation


enum BackendConfiguration {
    static var baseURL: URL {
        #if targetEnvironment(simulator)
        URL(string: "http://127.0.0.1:3001")!
        #else
        URL(string: "https://twannaing-unabating-floy.ngrok-free.dev")!
        #endif
    }
}

