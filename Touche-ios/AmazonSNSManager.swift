//
//  AmazonSNSManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/18/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit
import AWSSNS
import SwiftyJSON

class AmazonSNSManager {

    let SNSPlatformApplicationArnSandbox = "arn:aws:sns:us-east-1:814911031821:app/APNS_SANDBOX/toucheapp"
    let SNSPlatformApplicationArnProduction = "arn:aws:sns:us-east-1:814911031821:app/APNS/toucheapp"

    // MARK: Properties
    static let sharedInstance: AmazonSNSManager = AmazonSNSManager()

    func buildNotificationSettings() -> UIUserNotificationSettings {
        // Configures the appearance
        UINavigationBar.appearance().barTintColor = UIColor.black
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent

        // Sets up Mobile Push Notification
        let readAction = UIMutableUserNotificationAction()
        readAction.identifier = "READ_IDENTIFIER"
        readAction.title = "Read"
        readAction.activationMode = UIUserNotificationActivationMode.foreground
        readAction.isDestructive = false
        readAction.isAuthenticationRequired = true

        let deleteAction = UIMutableUserNotificationAction()
        deleteAction.identifier = "DELETE_IDENTIFIER"
        deleteAction.title = "Delete"
        deleteAction.activationMode = UIUserNotificationActivationMode.foreground
        deleteAction.isDestructive = true
        deleteAction.isAuthenticationRequired = true

        let ignoreAction = UIMutableUserNotificationAction()
        ignoreAction.identifier = "IGNORE_IDENTIFIER"
        ignoreAction.title = "Ignore"
        ignoreAction.activationMode = UIUserNotificationActivationMode.foreground
        ignoreAction.isDestructive = false
        ignoreAction.isAuthenticationRequired = false

        let messageCategory = UIMutableUserNotificationCategory()
        messageCategory.identifier = "MESSAGE_CATEGORY"
        messageCategory.setActions([readAction, deleteAction], for: UIUserNotificationActionContext.minimal)
        messageCategory.setActions([readAction, deleteAction, ignoreAction], for: UIUserNotificationActionContext.default)

        let notificationSettings = UIUserNotificationSettings(types: [UIUserNotificationType.badge, UIUserNotificationType.sound, UIUserNotificationType.alert], categories: (NSSet(array: [messageCategory])) as? Set<UIUserNotificationCategory>)

        return notificationSettings
    }

    func registerForPush(_ deviceTokenString: String) {

        print("deviceTokenString: \(deviceTokenString)")

        UserDefaults.standard.set(deviceTokenString, forKey: "deviceToken")

        let sns = AWSSNS.default()
        if let request = AWSSNSCreatePlatformEndpointInput() {
            request.token = deviceTokenString


            let _ = ProvisioningProfileParser(success: {
                //the parser does it's work in a background thread; this callback is now on the main UI thread
                //ProvisioningProfile.sharedProfile is a singleton

                // if the name in development looks like this: "match Development com.toucheapp.Touche"
                if (ProvisioningProfile.sharedProfile.name.contains("Development")) {
                    request.platformApplicationArn = self.SNSPlatformApplicationArnSandbox
                } else {
                    request.platformApplicationArn = self.SNSPlatformApplicationArnProduction
                }

                sns.createPlatformEndpoint(request).continueWith(block: { (task: AWSTask) -> Void in
                    if task.error != nil {
                        print("Error: \(task.error)")
                    } else {
                        let createEndpointResponse = task.result as! AWSSNSCreateEndpointResponse
                        print("endpointArn: \(createEndpointResponse.endpointArn)")

                        // todo: store in user defaults
                        // UserDefaults.s(createEndpointResponse.endpointArn, forKey: "endpointArn")

                        // also store in firebase so that we know how to message a user
                        FirebasePeopleManager.sharedInstance.storeInProfile(createEndpointResponse.endpointArn!, forKey: "endpointArn")
                    }
                })

            })
        }

    }

    func sendPush(_ text: String, userUUID: String, endpointArn: String) {

        let sns = AWSSNS.default()

        if let request = AWSSNSPublishInput() {
//            FirebaseChatManager.sharedInstance.getTotalUnreadMessagesFor(userUUID) {
//                (total) in
//
//            }

            do {

                print(endpointArn)

                let endpointArr = endpointArn.characters.split(separator: "/")
                let endpointType = String(endpointArr[1])

                request.messageStructure = "json"

                let devicePayLoad = ["default": "\(text)", "\(endpointType)": "{\"aps\":{\"alert\": \"\(text)\",\"sound\":\"default\", \"badge\":\"1\"}}"]

                let jsonData = try JSONSerialization.data(withJSONObject: devicePayLoad, options: JSONSerialization.WritingOptions.init(rawValue: 0))

                request.subject = "\(text)"
                request.message = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as? String
                request.targetArn = endpointArn

                sns.publish(request) {
                    (response, error) in
                    print(response)
                    if error != nil {
                        print(error)
                    }
                }

            } catch {
                print("Error on json serialization: \(error)")
            }

        }

//        {
//                "aps":{
//                    "alert":"Test APNS Notification",
//                    "sound":"default",
//                    "badge":10
//                }
//        }


    }

}
