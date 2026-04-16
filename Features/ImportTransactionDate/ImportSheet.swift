//
//  ImportSheet.swift
//  Bujet
//
//  Created by Zachary Beck on 15/04/2026.
//

import Foundation

enum ImportSheet: String, Identifiable {
    case options
    case dateRange

    var id: String { rawValue }
}
