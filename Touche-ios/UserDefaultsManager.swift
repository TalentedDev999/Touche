//
//  UserDefaultsManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

class UserDefaultsManager {
    
    // MARK: Properties
    
    struct Keys {
        static let firebaseToken = "firebaseToken"
        static let algoliaToken = "algoliaToken"
        static let firebaseTokenTimestamp = "firebaseTokenTimestamp"
        static let algoliaTokenTimestamp = "algoliaTokenTimestamp"
    }
    
    static let sharedInstance = UserDefaultsManager()
    
    fileprivate var ud:UserDefaults
    
    // MARK: Constructor

    fileprivate init () {
        ud = UserDefaults.standard
    }
    
    // MARK: - Methods
    
    func setCustomValue(_ v:String, forKey k:String) -> Void {
        ud.setValue(v, forKey: k)
    }
    
    func deleteForKey(forKey k:String) -> Void {
        ud.removeObject(forKey: k)
    }
    
    func getValueForKey(_ k:String) -> String? {
        return ud.string(forKey: k)
    }

}
