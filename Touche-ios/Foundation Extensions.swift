//
//  Foundation Extensions.swift
//  Touche-ios
//
//  Created by Lucas Maris on 20/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

extension Int {
    static func random(_ max: Int) -> Int {
        return Int(arc4random() % UInt32(max))
    }
}

extension Double {
    static func random() -> Double {
        return drand48()
    }
}
