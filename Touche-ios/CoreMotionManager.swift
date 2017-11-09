//
//  CoreMotionManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 18/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import CoreMotion

class CoreMotionManager {

    // MARK: Properties

    static let sharedInstance = CoreMotionManager()

    fileprivate var motion: CMMotionManager

    // MARK: Constructor

    fileprivate init() {
        motion = CMMotionManager()
    }

    // MARK: Methods

    func startAccelerometerUpdates(_ updateInterval: TimeInterval, handler: @escaping CMAccelerometerHandler) {
        if motion.isAccelerometerAvailable && !motion.isAccelerometerActive {
            motion.accelerometerUpdateInterval = updateInterval
            motion.startAccelerometerUpdates(to: OperationQueue.main, withHandler: handler)
        }
    }

    func stopAccelerometerUpdates() {
        motion.stopAccelerometerUpdates()
    }

}
