//
//  FirebaseManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/23/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import Firebase
import FirebaseAuth
import FirebaseDatabase
import SwiftyJSON
import AWSS3
import CoreLocation

class FirebaseManager {

    // MARK: - Properties

    static let sharedInstance = FirebaseManager()

    fileprivate var database: DatabaseReference


    fileprivate var latestKnownLat: Double
    fileprivate var latestKnownLon: Double

    fileprivate var polygons: [String] = []
    fileprivate var adjacentPolygons: [PolygonModel] = []

    // MARK: - Constructor

    fileprivate init() {
        FirebaseApp.configure()

        Database.database().isPersistenceEnabled = false

        database = Database.database().reference()

        latestKnownLat = 0
        latestKnownLon = 0
    }

    // MARK: - Methods

    /**
     * Token: JSON Token generated by Lambda function
     */
    func signInWithCustom(_ token: String, completion: @escaping AuthResultCallback) {

        Auth.auth().signIn(withCustomToken: token, completion: completion)

        // set the online status
    }

    func signOut() {
        try! Auth.auth().signOut()
    }

    func getAdjacentPolygons() -> [PolygonModel] {
        return adjacentPolygons
    }

    func refreshLocation() {
        if self.latestKnownLat != 0 && self.latestKnownLon != 0 {
            self.updateLocation(self.latestKnownLat, longitude: self.latestKnownLon)
        }
    }


    func updateLocation(_ latitude: Double, longitude: Double) {

        // todo: calculate velocity between the previous point and now

        self.latestKnownLat = latitude
        self.latestKnownLon = longitude

        if UserManager.sharedInstance.toucheUUID != nil && latestKnownLat != 0 && latestKnownLon != 0 {

            // notify geoManager
            GeoManager.sharedInstance.onLocationChanged(latitude, longitude: longitude)

            // update the seen value on profile
            FirebasePeopleManager.sharedInstance.setSeen(UserManager.sharedInstance.toucheUUID!)
        }
    }


    func getDatabaseReference(_ childNames: String...) -> DatabaseReference {
        var ref = database
        for childName in childNames {
            ref = ref.child(childName)
        }
        return ref
    }

    func getReference(_ from: DatabaseReference, childNames: String...) -> DatabaseReference {
        var ref = from
        for childName in childNames {
            ref = ref.child(childName)
        }
        return ref
    }

    // MARK : - Write Methods

    func setValue(_ reference: DatabaseReference, value: AnyObject?) {
        reference.setValue(value)
    }

    func setValue(_ reference: DatabaseReference, value: AnyObject?, completion: @escaping (Error?, DatabaseReference) -> Void) {
        reference.setValue(value, withCompletionBlock: completion)
    }

    func setValue(_ reference: DatabaseReference, key: String, value: AnyObject?) {
        reference.setValue(value, forKey: key)
    }

}