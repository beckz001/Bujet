//
//  ImportRangeCalendarView.swift
//  Bujet
//
//  Created by Zachary Beck on 15/04/2026.
//

import SwiftUI
import UIKit

struct ImportRangeCalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date

    let availableRange: ClosedRange<Date>
    var calendar: Calendar = .current
    var locale: Locale = .current

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = calendar
        calendarView.locale = locale
        calendarView.availableDateRange = DateInterval(
            start: availableRange.lowerBound,
            end: availableRange.upperBound
        )
        calendarView.tintColor = .systemPurple
        calendarView.backgroundColor = .secondarySystemBackground
        calendarView.layer.cornerCurve = .continuous
        calendarView.layer.cornerRadius = 12

        // Helps UICalendarView behave better in SwiftUI layout
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        selection.setSelected(dateComponents(from: selectedDate), animated: false)
        calendarView.selectionBehavior = selection

        calendarView.visibleDateComponents = calendar.dateComponents([.year, .month], from: selectedDate)

        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.parent = self

        uiView.calendar = calendar
        uiView.locale = locale
        uiView.availableDateRange = DateInterval(
            start: availableRange.lowerBound,
            end: availableRange.upperBound
        )

        if let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            let components = dateComponents(from: selectedDate)
            if selection.selectedDate != components {
                selection.setSelected(components, animated: true)
            }
        }

        let visibleComponents = calendar.dateComponents([.year, .month], from: selectedDate)
        if uiView.visibleDateComponents.year != visibleComponents.year ||
            uiView.visibleDateComponents.month != visibleComponents.month {
            uiView.setVisibleDateComponents(visibleComponents, animated: true)
        }
    }

    private func dateComponents(from date: Date) -> DateComponents {
        calendar.dateComponents([.year, .month, .day], from: calendar.startOfDay(for: date))
    }

    final class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate {
        var parent: ImportRangeCalendarView

        init(parent: ImportRangeCalendarView) {
            self.parent = parent
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard
                let dateComponents,
                let date = parent.calendar.date(from: dateComponents)
            else {
                return
            }

            parent.selectedDate = parent.calendar.startOfDay(for: date)
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
            guard
                let dateComponents,
                let date = parent.calendar.date(from: dateComponents)
            else {
                return false
            }

            let normalizedDate = parent.calendar.startOfDay(for: date)
            return normalizedDate >= parent.availableRange.lowerBound &&
                   normalizedDate <= parent.availableRange.upperBound
        }
    }
}
