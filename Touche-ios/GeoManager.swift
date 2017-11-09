//
//  GeoManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/25/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import SwiftLocation

class GeoManager {

    static let sharedInstance = GeoManager()

    var currentLocation: CLLocation? {
        didSet {
            if oldValue == nil {
                MessageBusManager.sharedInstance.postNotificationName(EventNames.Location.newLocationAvailable)
            }
        }
        willSet {
            if newValue != currentLocation {
                if let fresh: CLLocation = newValue, let old: CLLocation = currentLocation {
                    if fresh.coordinate.latitude != old.coordinate.latitude
                               && fresh.coordinate.longitude != old.coordinate.longitude {
                        self.updateLocation()
                    }
                }
            }
        }
    }


    fileprivate init() {

    }

    func onLocationChanged(_ latitude: Double, longitude: Double) {
        MessageBusManager.sharedInstance.postNotificationName(EventNames.Location.newLocationAvailable)

    }

    func updateLocation() {
        Utils.executeInBackgroundThread {

            let latitude = self.currentLocation!.coordinate.latitude
            let longitude = self.currentLocation!.coordinate.longitude

            AWSLambdaManager.sharedInstance.updateLocation(latitude, longitude: longitude) { result, exception, error in
                print("UpdateLocation has executed... \(result) \(error) \(exception)")
            }
        }
    }

    func fetchBackground() {
        Location.getLocation(accuracy: .any, frequency: .significant, success: { request, location in
            self.currentLocation = location
        }, error: { request, location, error in
            print(error)
        })
    }

    func fetchOnce() {
        Location.getLocation(accuracy: .neighborhood, frequency: .oneShot, timeout: (10.seconds).fromNow()!.timeIntervalSinceNow, success: { request, location in
            self.currentLocation = location
        }, error: { request, location, error in
            print(error)
            self.fallback()
        })
    }

    private func fallback() {
        Location.getLocation(accuracy: .any, frequency: .oneShot, timeout: (10.seconds).fromNow()!.timeIntervalSinceNow, success: { request, location in
            self.currentLocation = location
        }, error: { request, location, error in
            print(error)
        })
    }
}
