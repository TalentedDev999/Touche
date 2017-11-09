//
//  CoreLocationManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/8/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import SwiftLocation

class CoreLocationManager: NSObject {

    static let sharedInstance = CoreLocationManager()

    /**
     * This property it's automatically setted by CoreLocationDelegate
     * It's used for filter people by current location
     */
    var currentLocation: CLLocation?

    var updatingLocation = false {
        didSet {
            if updatingLocation {
                startUpdatingLocation()
            } else {
                stopUpdatingLocation()
            }
        }
    }

    fileprivate let lm: CLLocationManager

    // MAKR: Constructor

    fileprivate override init() {
        lm = CLLocationManager()

        super.init()

        lm.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        lm.distanceFilter = kCLDistanceFilterNone
        lm.delegate = self

        requestWhenInUseAuthorization()
        initialize()
    }

    func initialize() {
        startUpdatingLocation()
//        Location.getLocation(accuracy: .neighborhood, frequency: .continuous, timeout: , success: { request, location in
//            self.currentLocation = location
//        }, error: { request, location, error in
//            print(error)
//        })

    }

    // MARK: Methods

    fileprivate func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() == .notDetermined {
                lm.requestAlwaysAuthorization()
                return
            }

            if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
                lm.requestAlwaysAuthorization()
                return
            }

            lm.startUpdatingLocation()
        }
    }

    fileprivate func stopUpdatingLocation() {
        lm.stopUpdatingLocation()
    }

    fileprivate func requestAllwaysUseAuthorization() -> Void {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            lm.requestAlwaysAuthorization()
        }

        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            allwaysUsePermissionsError()
        }
    }

    fileprivate func requestWhenInUseAuthorization() -> Void {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            lm.requestWhenInUseAuthorization()
        }

        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            whenInUsePermissionsError()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            lm.stopUpdatingLocation()
            MessageBusManager.sharedInstance.postNotificationName(EventNames.Location.newLocationAvailable)
        }
    }

    // MARK: - Messages Error

    func allwaysUsePermissionsError() {
        let alertController = UIAlertController(title: "Allow touché to access your location even when you are not using the app?",
                message: "To filter users who are near your location",
                preferredStyle: UIAlertControllerStyle.alert
        )

        let dontAllowAction = UIAlertAction(title: "Don't Allow", style: .default) { (action) in
            let dontAllowEvent = EventNames.Location.Dialog.dontAllow
            MessageBusManager.sharedInstance.postNotificationName(dontAllowEvent)
        }

        let allowAction = UIAlertAction(title: "Allow", style: .default) { (action) in
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(settingsURL)
            }
        }

        alertController.addAction(dontAllowAction)
        alertController.addAction(allowAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }

    func whenInUsePermissionsError() {
        let alertController = UIAlertController(title: "Allow touché to access your location while you use the app?",
                message: "To filter users who are near your location",
                preferredStyle: UIAlertControllerStyle.alert
        )

        let dontAllowAction = UIAlertAction(title: "Don't Allow", style: .default) { (action) in
            let dontAllowEvent = EventNames.Location.Dialog.dontAllow
            MessageBusManager.sharedInstance.postNotificationName(dontAllowEvent)
        }

        let allowAction = UIAlertAction(title: "Allow", style: .default) { (action) in
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(settingsURL)
            }
        }

        alertController.addAction(dontAllowAction)
        alertController.addAction(allowAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }

    // MARK : - Helpers

    func getCLLocationCoordinate2DFrom(_ lat: Double, lng: Double) -> CLLocationCoordinate2D? {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    func getCLLocationCoordinate2DFrom(_ lat: String, lng: String) -> CLLocationCoordinate2D? {
        if let auxLat = Double(lat), let auxLng = Double(lng) {
            return getCLLocationCoordinate2DFrom(auxLat, lng: auxLng)
        }

        return nil
    }

    func getCurrentLatitude() -> Double? {
        return currentLocation?.coordinate.latitude
    }

    func getCurrentLongitude() -> Double? {
        return currentLocation?.coordinate.longitude
    }

    func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * M_PI / 180.0
    }

    func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / M_PI
    }

    func getBearingBetweenTwoPoints(_ point1: CLLocation, point2: CLLocation) -> String {

        let lat1 = degreesToRadians(point1.coordinate.latitude)
        let lon1 = degreesToRadians(point1.coordinate.longitude)

        let lat2 = degreesToRadians(point2.coordinate.latitude)
        let lon2 = degreesToRadians(point2.coordinate.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        let degrees = radiansToDegrees(radiansBearing)

        if degrees > 0 {
            if degrees > 90 {
                return "SE"
            }
            return "NE"
        } else {
            if degrees < -90 {
                return "SW"
            }
            return "NW"
        }
    }

}
