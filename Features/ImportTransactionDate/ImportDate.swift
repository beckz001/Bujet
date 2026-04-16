//
//  ImportDate.swift
//  Bujet
//
//  Created by Zachary Beck on 15/04/2026.
//

import Foundation

struct ImportDateRange: Equatable {
    var startDate: Date
    var endDate: Date

    var closedRange: ClosedRange<Date> {
        startDate...endDate
    }
}

enum ImportRangeBoundary {
    case start
    case end
}
