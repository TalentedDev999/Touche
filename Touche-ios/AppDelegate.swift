//
//  AppDelegate.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/4/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import CoreData

import AWSCognito
import AWSSNS
import GoogleMobileAds

import FBSDKCoreKit

import Fabric
import Crashlytics
import Siren
import Mapbox
import AppsFlyerLib

import MoPub
import Tabby
import Cupcake


//import slaask


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


//    lazy var homeController: TabbyController = { [unowned self] in
//        let controller = HomeController(items: self.items)
//        let nc = controller.navigationController
//        controller.delegate = self
//        controller.translucent = false
//        return controller
//    }()



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)



        //let navigationController = UINavigationController(rootViewController: controller)
        //navigationController.topViewController?.title = "Hello World"
        //navigationController.navigationBar.isHidden = true

        //Utils.navigationControllerSetup(navigationController)

        self.window?.rootViewController = SetupController()
        self.window?.makeKeyAndVisible()

        let siren = Siren.shared

        siren.alertType = .force
        siren.checkVersion(checkType: .immediately)

        //let config      = SLAASKConfig.init(slaaskToken: "866a891d2d30b4905bf82d675ed7fb72")
        //let manager     = SLAASKManager.sharedInstance
        //manager.config  = config

        AppsFlyerTracker.shared().appleAppID = "1076156218";
        AppsFlyerTracker.shared().appsFlyerDevKey = "oPW35LxKRQwTauxvNNg4KR";

        Fabric.with([MoPub.self, Answers.self, Crashlytics.self, AWSCognito.self, MGLAccountManager.self])

        MPAdConversionTracker.shared().reportApplicationOpen(forApplicationID: "1076156218")

        GADMobileAds.configure(withApplicationID: "ca-app-pub-1776679942378900~1243695274")

        // Push notification settings
        let notificationSettings = AmazonSNSManager.sharedInstance.buildNotificationSettings()
        UIApplication.shared.registerForRemoteNotifications()
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)

        // Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        AppBadgeManager.sharedInstance.setAppBadgeCount(application.applicationIconBadgeNumber)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

        if UserManager.sharedInstance.toucheUUID != nil {
            FirebasePeopleManager.sharedInstance.setStatus(FirebasePeopleManager.Database.Profile.Status.Offline)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        if UserManager.sharedInstance.toucheUUID != nil {
            FirebasePeopleManager.sharedInstance.setStatus(FirebasePeopleManager.Database.Profile.Status.Offline)
        }

        // Upload TreasureData events
        AnalyticsManager.sharedInstance.applicationDidEnterBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        Siren.shared.checkVersion(checkType: .immediately)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FirebaseManager.sharedInstance.refreshLocation()
        if UserManager.sharedInstance.toucheUUID != nil {
            FirebasePeopleManager.sharedInstance.setStatus(FirebasePeopleManager.Database.Profile.Status.Online)
        }

        // Facebook
        FBSDKAppEvents.activateApp()

        // AppsFlyer
        AppsFlyerTracker.shared().trackAppLaunch()

        Siren.shared.checkVersion(checkType: .immediately)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.

        if UserManager.sharedInstance.toucheUUID != nil {
            FirebasePeopleManager.sharedInstance.setStatus(FirebasePeopleManager.Database.Profile.Status.Offline)
        }

        // Log the Events to Treasure Data
        AnalyticsManager.sharedInstance.applicationWillTerminate()
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {

        // Facebook
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    // MARK: - Core Data stack



    // MARK: - Push Notifications

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        let token = deviceToken.map {
            String(format: "%02.2hhx", $0)
        }.joined()

        // Successfully registered with Apple Push Notification service (APNs).
        UserDefaults.standard.set(token, forKey: "applePushDeviceToken")

        Utils.executeInBackgroundThread {
            if UserManager.sharedInstance.toucheUUID != nil {
                AmazonSNSManager.sharedInstance.registerForPush(token)
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Register for remote notifications fail")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("did receive remote notification")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("did receive remote notification with completion handler")
    }

}



