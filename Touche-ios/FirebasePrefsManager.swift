//
//  FirebaseBankManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/23/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import Firebase
import CryptoSwift

class FirebasePrefsManager {

    static let sharedInstance = FirebasePrefsManager()

    fileprivate var prefsTable = [String: Any]()

    public var within = [String]()

    fileprivate init() {

    }

    func save(_ key: String, value: [String]) {
        if let uuid = UserManager.sharedInstance.toucheUUID {

            // save immediately
            self.prefsTable[key] = value

            let preferenceRef = Database.database().reference().child("profile")
                    .child(uuid)
                    .child("preferences")
                    .child(key)

            preferenceRef.setValue(value)

            print("saved preference \(key)=\(value)")
        }
    }

    func save(_ key: String, value: String) {
        if let uuid = UserManager.sharedInstance.toucheUUID {
            // save immediately
            self.prefsTable[key] = value

            let preferenceRef = Database.database().reference().child("profile")
                    .child(uuid)
                    .child("preferences")
                    .child(key)
            preferenceRef.setValue(value)
            print("saved preference \(key)=\(value)")
        }
    }

    func pref(_ key: String) -> AnyObject? {
        if let value = prefsTable[key] {
            return value as! AnyObject
        }
        return nil
    }

    func setupUserRef() {
        if let uuid = UserManager.sharedInstance.toucheUUID {

            let prefsRef = Database.database().reference().child("profile")
                    .child(uuid)
                    .child("preferences")

            //prefsRef.keepSynced(true)

            prefsRef.observe(.childAdded, with: {
                (snapshot) in
                if let value = snapshot.value as? String {
                    print("new pref added: \(snapshot.key)=\(value)")
                    self.prefsTable[snapshot.key] = value
                }
            })

            prefsRef.observe(.childChanged, with: {
                (snapshot) in
                if let value = snapshot.value as? String {
                    print("new pref changed: \(snapshot.key)=\(value)")
                    self.prefsTable[snapshot.key] = value
                }
            })

            prefsRef.observe(.childRemoved, with: {
                (snapshot) in
                if let value = snapshot.value as? String {
                    print("new pref removed: \(snapshot.key)=\(value)")
                    self.prefsTable.removeValue(forKey: snapshot.key)
                }
            })
        }
    }

}
