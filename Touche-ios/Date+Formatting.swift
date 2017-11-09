//
//  Date+Formatting.swift
//  Touche-ios
//
//  Created by Lucas Maris on 27/06/2017.
//  Copyright © 2017 toucheapp. All rights reserved.
//

import Foundation

extension Date {
    
    func daysUntilToday() -> Int {
        return daysUntil(date: Date())
    }
    
    func daysUntil(date: Date) -> Int {
        let calendar = Calendar.current
        let date1 = calendar.startOfDay(for: self)
        let date2 = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([Calendar.Component.day], from: date1, to: date2)
        return components.day!
    }
    
    func remainingDays() -> String {
        if daysUntilToday() == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: self)
        } else {
            let days = daysUntilToday()
            return String(format: days == 1 ? "yesterday".translate() : "%d days ago", days)
        }
    }
    
}
