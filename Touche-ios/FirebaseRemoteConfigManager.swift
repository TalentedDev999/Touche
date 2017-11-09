//
// Created by Lucas Maris on 9/22/16.
// Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import Firebase
import FirebaseRemoteConfig

class FirebaseRemoteConfigManager {

    // MARK: - Properties

    struct Keys {
        static let inAppPurchaseEnv = "inAppPurchaseEnv"
        static let defaultUsageLimit = "defaultUsageLimit"
    }
    
    static let sharedInstance = FirebaseRemoteConfigManager()

    fileprivate let remoteConfig: RemoteConfig
    
    var isRemoteValid = false

    // MARK: - Init Methods

    fileprivate init() {
        remoteConfig = RemoteConfig.remoteConfig()
        
        // developerModeEnabled for quickly refresh
        remoteConfig.configSettings = RemoteConfigSettings(developerModeEnabled: true)!
        
        remoteConfig.fetch(withExpirationDuration: 1, completionHandler: { (status, error) in
            if error != nil {
                self.isRemoteValid = false
                return
            }

            if status == RemoteConfigFetchStatus.success {
                self.remoteConfig.activateFetched()
                self.isRemoteValid = true
            } else {
                self.isRemoteValid = false
            }
        })
    }
    
    func initialize() {}
    
    // MARK: - Methods

    func getStringValueFor(_ key:String) -> String? {
        return remoteConfig[key].stringValue
    }
    
    func getNumberValueFor(_ key:String) -> NSNumber? {
        return remoteConfig[key].numberValue
    }
    
    func getBoolValueFor(_ key:String) -> Bool? {
        return remoteConfig[key].boolValue
    }
    
    func getDateValueFor(_ key:String) -> Data? {
        return remoteConfig[key].dataValue
    }
    
}
