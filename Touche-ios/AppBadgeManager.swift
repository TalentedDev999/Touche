//
//  AppBadgeManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 11/10/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit

class AppBadgeManager {

    // MARK: - Properties
    
    static let sharedInstance = AppBadgeManager()
    
    fileprivate var appBadgeCount:Int
    
    // MARK: - Init Method
    
    fileprivate init() {
        appBadgeCount = 0
    }
    
    // MARK: - Methods
    
    func getAppBadgeCount() -> Int {
        return appBadgeCount
    }
    
    func setAppBadgeCount(_ badgeValue:Int) {
        appBadgeCount = badgeValue
    }
    
    func changeAppBadgeCountTo(_ value:Int) {
        if value >= 0 {
            appBadgeCount = value
            UIApplication.shared.applicationIconBadgeNumber = value
        }
    }
    
    func substractFromAppBadgeCount(_ value:Int) {
        if value >= 0 && value <= appBadgeCount {
            let newAppBadgeCount = appBadgeCount - value
            changeAppBadgeCountTo(newAppBadgeCount)
        }
    }
    
    func sumToAppBadgeCount(_ value:Int) {
        if value >= 0 {
            let newAppBadgeCount = appBadgeCount + value
            changeAppBadgeCountTo(newAppBadgeCount)
        }
    }
    
}
