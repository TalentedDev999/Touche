//
//  PeopleManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 5/8/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftDate

class PeopleManager {

    // MARK: Properties

    static let sharedInstance = PeopleManager()

    public var lastTouch: Date = Date()

    public func hasInteractedRecently() -> Bool {
        let hasInteracted = lastTouch.isAfter(date: (10.seconds).ago()!, granularity: Calendar.Component.second)
        return hasInteracted
    }

    func getProfile(_ uuid: String) {

    }

}
