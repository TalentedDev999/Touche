//
//  UserManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 21/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import FirebaseAuth
import AppsFlyerLib

class UserManager {

    // MARK: Properties

    static let sharedInstance = UserManager()

    // MARK: - Services Tokens

    var cognitoIdentityId: String? {
        didSet {
            if cognitoIdentityId != nil {
                MessageBusManager.sharedInstance.postNotificationName(EventNames.Login.cognitoIdentityIdAvailable)
            }
        }
    }

    var servicesReady = false

//    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    var toucheUUID: String? {
        didSet {
            if toucheUUID != nil {
                MessageBusManager.sharedInstance.postNotificationName(EventNames.Login.toucheUUIDAvailable)
            }
        }
    }

    func login() {
        LoginManager.requestTokens(toucheUUID!)

//                backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
//                    UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
//                })

        let selector = #selector(UserManager.backgroundRefresh)

        Timer.scheduledTimer(timeInterval: 60, target: self, selector: selector, userInfo: nil, repeats: true)

        // Register for push notification
        let deviceToken = UserDefaults.standard.object(forKey: "applePushDeviceToken") as? String
        if deviceToken != nil {
            AmazonSNSManager.sharedInstance.registerForPush(deviceToken!)
        }

        // reset local refs
        //FirebaseChatManager.sharedInstance.setupUserRef()
        //FirebaseIAPManager.sharedInstance.setupUserRef()
        //FirebasePrefsManager.sharedInstance.setupUserRef()

        // appsflyer
        AppsFlyerTracker.shared().customerUserID = self.toucheUUID
    }

    var firebaseToken: String? {
        didSet {
            if firebaseToken != nil {
                LoginManager.signinWithFirebase(firebaseToken!)
            }
        }
    }

    var algoliaToken: String? {
        didSet {
            if algoliaToken != nil {

            }
        }
    }

    var twilioToken: String?

    // MARK: - Services Models

    var firebaseUser: User? {
        didSet {
            //FirebaseRemoteConfigManager.sharedInstance.initialize()

            MessageBusManager.sharedInstance.postNotificationName(EventNames.Login.firebaseReady)

            //MessageBusManager.sharedInstance.postNotificationName(EventNames.Login.services_available)

            self.servicesReady = true
        }
    }

    var isPlaying = false
    var numberOfCycles = 0

    fileprivate init() {
    }

    // MARK: Methods

    func setupIAP() {
        FirebaseIAPManager.sharedInstance.getIAPSubscription { (validSubscription) in

            FirebaseIAPManager.sharedInstance.subcriptionsWereReceived = true

            if let subscription = validSubscription {
                // There is a valid subscription, so then the user becomes Premium
                IAPManager.sharedInstance.currentSubscription = subscription
            }

            MessageBusManager.sharedInstance.postNotificationName(EventNames.Login.iapReady)
        }

        FirebaseIAPManager.sharedInstance.getIAPProductsIdentifiers {
            (productsIdentifiers) in
            if let productsIdentifiers = productsIdentifiers {
                // Retrieve products from Apple Store based on the identifiers
                IAPManager.sharedInstance.productsIdentifiers = productsIdentifiers

                FirebaseIAPManager.sharedInstance.getIAPProductsData(productsIdentifiers, completion: {
                    (productsData) in
                    if let productsData = productsData {
                        IAPManager.sharedInstance.productsData = productsData
                    }
                })

            }
        }
    }

    static func isDebug() -> Bool {
        #if DEBUG
                return true
        #else
                return false
        #endif
    }

    func locale() -> String {
        return Locale.preferredLanguages[0]
    }

    func lang() -> String {
        return locale().contains("-") ? locale().components(separatedBy: "-")[0] : locale()
    }

    func version() -> String {
        if var version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            version = version + "-" + buildNumber
            if (UserManager.isDebug() || ProvisioningProfile.sharedProfile.name.contains("Development") || "SANDBOX" == IAPManager.sharedInstance.getEnv()) {
                version = version + " beta"
            }
            return version
        }
        return "Unknown"
    }


    @objc func backgroundRefresh() {
        print("executing background refresh...")
        LoginManager.requestTokens(toucheUUID!)
    }

    func isPremium() -> Bool {
        if let currentSubscription = IAPManager.sharedInstance.currentSubscription {
            return currentSubscription.isAValidSubscription()
        }

        return false
    }

}
