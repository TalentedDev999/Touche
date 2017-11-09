//
//  CoreLocationDelegate.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/8/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import CoreLocation

extension CoreLocationManager : CLLocationManagerDelegate {
    
    // MARK: - Helpers
    
    fileprivate func isANewLocation(_ location:CLLocation) -> Bool {
        if currentLocation == nil {
            return true
        }
        
        let threshold = 0.3
        let latDiff = currentLocation!.coordinate.latitude - location.coordinate.latitude
        let lonDiff = currentLocation!.coordinate.longitude - location.coordinate.longitude
        
        if abs(latDiff) > threshold || abs(lonDiff) > threshold {
            return true
        }
        
        return false
    }
    
    // MARK: - CLLocation Manager Delegate
    
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        print("Location Authorization was changed to \(status.rawValue)")
//
//        if status != .notDetermined && status != .authorizedWhenInUse {
//            whenInUsePermissionsError()
//            return
//        }
//
//        if status == .authorizedWhenInUse {
//            let locationAuthWhenInUseEvent = EventNames.Location.AuthorizationChanged.authorizedWhenInUsed
//            MessageBusManager.sharedInstance.postNotificationName(locationAuthWhenInUseEvent)
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let newLocation = locations.first {
//            if isANewLocation(newLocation) {
//                currentLocation = newLocation
//
//                let latitude = newLocation.coordinate.latitude
//                let longitude = newLocation.coordinate.longitude
//                //let elevation = newLocation.altitude
//
//                FirebaseManager.sharedInstance.updateLocation(latitude, longitude: longitude)
//
//                let newLocationAvailableEvent = EventNames.Location.newLocationAvailable
//                MessageBusManager.sharedInstance.postNotificationName(newLocationAvailableEvent)
//            }
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
//        print("LocationDelegate: didUpdateToLocation")
//    }
//
//    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
//        print("LocationDelegate: didResumeLocationUpdates")
//    }
//
//    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
//        print("LocationDelegate: didPauseLocationUpdates")
//    }
//
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("LocationDelegate: didFailWithError: \(error.localizedDescription)")
//    }

}
