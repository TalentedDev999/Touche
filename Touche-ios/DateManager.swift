//
//  DateManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 22/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

class DateManager {
    
    enum DateProximity {
        case today
        case yesterday
        case week
        case year
        case other
    }
    
    static func getProximityOfDate(_ date:Date) -> DateProximity {
        let calendar = Calendar.current
        let now = Date()
        
        let dateComponents = (calendar as NSCalendar).components(.era, from: date)
        let nowComponents = (calendar as NSCalendar).components(.era, from: now)
        
        let date_day = dateComponents.day
        let date_month = dateComponents.month
        let date_year = dateComponents.year
        let date_era = dateComponents.era
        
        let now_day = nowComponents.day
        let now_month = nowComponents.month
        let now_year = nowComponents.year
        let now_era = nowComponents.era
        
        if date_day == now_day &&
            date_month == now_month &&
            date_year == now_year &&
            date_era == now_era
        {
            return .today
        }
        
        let yesterdayComponents = DateComponents()

        let yesterday_day = yesterdayComponents.day
        let yesterday_month = yesterdayComponents.month
        let yesterday_year = yesterdayComponents.year
        let yesterday_era = yesterdayComponents.era
        
        if now_day == yesterday_day &&
            now_month == yesterday_month &&
            now_year == yesterday_year &&
            now_era == yesterday_era
        {
            return .yesterday
        }
        
        let date_week_of_month = dateComponents.weekOfMonth
        let now_week_of_month = nowComponents.weekOfMonth
        
        if date_week_of_month == now_week_of_month &&
            date_month == now_month &&
            date_year == now_year &&
            date_era == now_era
        {
            return .week
        }
        
        if date_year == now_year && date_era == now_era {
            return .year
        }
        
        return .other
    }
    
    // MARK: - Current Date
    
    static func getCurrentMillis() -> String? {
        let currentSecods = Date().timeIntervalSince1970
        return String(Int64(currentSecods * 1000))
        
    }
    
    // MARK: - Date Formats
    
    static func getShortTimeFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        return dateFormatter
    }
    
    static func getRelativeDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }
    
    static func getDayOfWeekFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter
    }

    static func getYearMonthDayFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMMM, dd"
        return dateFormatter
    }
    
    static func getHoursWithMinutesFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }
    
    static func getDefaultFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter
    }
    
    static func getFormatterByProximity(_ proximity:DateManager.DateProximity) -> DateFormatter {
        switch proximity {
        case .today, .yesterday:
            return getRelativeDateFormatter()
        case .week:
            return getDayOfWeekFormatter()
        case .year:
            return getYearMonthDayFormatter()
        case .other:
            return getDefaultFormatter()
        }
    }
    
    class func getFormattedDateFromString(_ stringDate:String, format:String) -> Date? {
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        if let date = dateFormatter.date(from: stringDate) {
            return date
        }
        
        return nil
    }
    
    class func getFormattedStringFromDate(_ date:Date, format:String) -> String? {
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        return dateFormatter.string(from: date)
    }
    
    class func getFormattedStringFromStringDate(_ srcStringDate:String, srcFromat:String, dstFormat:String) -> String? {
        if let srcDate:Date = getFormattedDateFromString(srcStringDate, format: srcFromat) {
            if let dstDate:String = getFormattedStringFromDate(srcDate, format: dstFormat) {
                return dstDate
            }
            
            return nil
        }
        
        return nil
    }
    
    class func getDayNameFromDate(_ date:Date) -> String {
        let calendar:Calendar = Calendar.current
        let components:DateComponents = (calendar as NSCalendar).components([NSCalendar.Unit.weekday], from: date)
        let weekDays:[String] = ["", "Dom.", "Lun.", "Mar.", "Mier.", "Juev.", "Vier.", "Sab."] // todo: Spanish??????
        
        return weekDays[components.weekday!]
    }
    
    class func getDayNameFromStringDateWithFormat(_ strDate:String, format:String) -> String? {
        if let date:Date = getFormattedDateFromString(strDate, format: format) {
            return getDayNameFromDate(date)
        }
        
        return nil
    }
    
    class func getDateFromMillis(_ millis:String) -> Date? {
        if let timeIntervalSince1970 = TimeInterval(millis) {
            return Date(timeIntervalSince1970: timeIntervalSince1970 / 1000)
        }
        
        return nil
    }
    
    // MARK: - Dates Comparations
    
    class func isCurrentTimeGreaterThan(_ msSince1970:String) -> Bool {
        if let msTimeIntervalSince1970 = Double(msSince1970) {
            let date = Date(timeIntervalSince1970: msTimeIntervalSince1970 / 1000) // TimeIntervalSince1970 must be in seconds
            return isCurrentTimeGreaterThan(date)
        }
        
        return false
    }
    
    class func isDateGreaterThan(_ date:Date, anotherDate:Date) -> Bool {
        var isGreater = false
        
        if date.compare(anotherDate) == ComparisonResult.orderedDescending {
            isGreater = true
        }
        
        return isGreater
    }
    
    class func isCurrentTimeGreaterThan(_ date:Date) -> Bool {
        let currentDate = Date()
        
        var isGreater = false
        if currentDate.compare(date) == ComparisonResult.orderedDescending {
            isGreater = true
        }
        
        return isGreater
    }
    
    class func isCurrentTimeLessThan(_ msSince1970:String) -> Bool {
        if let msTimeIntervalSince1970 = Double(msSince1970) {
            let date = Date(timeIntervalSince1970: msTimeIntervalSince1970 / 1000) // TimeIntervalSince1970 must be in seconds
            return isCurrentTimeLessThan(date)
        }
        
        return false
    }
    
    class func isCurrentTimeLessThan(_ date:Date) -> Bool {
        let currentDate = Date()
        
        var isLess = false
        if currentDate.compare(date) == ComparisonResult.orderedAscending {
            isLess = true
        }
        
        return isLess
    }
    
    class func isDateLessThan(_ date:Date, anotherDate:Date) -> Bool {
        var isLess = false
        
        if date.compare(anotherDate) == ComparisonResult.orderedAscending {
            isLess = true
        }
        
        return isLess
    }
    
    class func isCurrentTimeEqualTo(_ date:Date) -> Bool {
        let currentDate = Date()
        
        var isEqualTo = false
        if currentDate.compare(date) == ComparisonResult.orderedSame {
            isEqualTo = true
        }
        
        return isEqualTo
    }
    
    class func getNumberOfDaysFromCurrentDateTo(_ date:Date) -> Int {
        if isCurrentTimeLessThan(date) {
            let currentDate = Date()
            let calendar = Calendar.current
            
            let fromDate = calendar.startOfDay(for: currentDate)
            let toDate = calendar.startOfDay(for: date)
            
            let flags = NSCalendar.Unit.day
            let components = (calendar as NSCalendar).components(flags, from: fromDate, to: toDate, options: [])
            return components.day!
        }
        
        return -1
    }
    
    class func getNumberOfDaysFromCurrentDateTo(_ msSince1970:String) -> Int {
        if let msTimeIntervalSince1970 = Double(msSince1970) {
            let date = Date(timeIntervalSince1970: msTimeIntervalSince1970 / 1000) // TimeIntervalSince1970 must be in seconds
            return getNumberOfDaysFromCurrentDateTo(date)
        }
        
        return -1
    }
    
    static func getWeekDayAndDateStringFrom(_ date:Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "EEEE, MM dd yyyy"  // "Monday, Mar 7 2016"
        return dateFormatter.string(from: date)
    }
    
    static func getCurrentDateByAdding(_ unit:NSCalendar.Unit, value:Int, options:NSCalendar.Options) -> Date? {
        let calendar = Calendar.current
        let currentDate = Date()
        return (calendar as NSCalendar).date(byAdding: unit, value: value, to: currentDate, options: options)
    }
    
}
