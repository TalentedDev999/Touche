//
//  NotificationsManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/21/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import SwiftMessages

class NotificationsManager {
    
    static let sharedInstance = NotificationsManager()
    
    fileprivate init() {}
    
    func sendNotification(_ recipientUUID: String, title:String, text: String) {
        FirebasePeopleManager.sharedInstance.getProfile(recipientUUID) { (profile) in
            guard let profile = profile else { return }
            
            var status = FirebasePeopleManager.Database.Profile.Status.Offline
            if let myBeautifulStatus = profile.status {
                status = myBeautifulStatus
            }

            // Recipient is offline - send push notification
            if status == FirebasePeopleManager.Database.Profile.Status.Offline {
                self.sendPushNotification(profile, userUUID: recipientUUID, text: text)
            }
        }
    }

    func sendPushNotificationIfUserOffline(_ uuid: String, text: String) {
        FirebasePeopleManager.sharedInstance.getProfile(uuid) { (profile) in
            guard let profile = profile else { return }
            
            var status = FirebasePeopleManager.Database.Profile.Status.Offline
            if let myBeautifulStatus = profile.status {
                status = myBeautifulStatus
            }
            
            if status == FirebasePeopleManager.Database.Profile.Status.Offline {
                self.sendPushNotification(profile, userUUID: uuid, text: text)
            }
        }
    }
    
    func showInAppNotificationFrom(_ title:String, senderUUID:String, body:String, tapHandler:((_ view:BaseView) -> Void)?) {
        PhotoManager.sharedInstance.getAvatarImageFor(senderUUID) { (image) in
            self.showInAppNotification(title, body: body, iconImage: image, tapHandler: tapHandler)
        }
    }
    
    func showError(_ text: String) {
        let view = MessageView.viewFromNib(layout: .StatusLine)
//        view.configureTheme(.error)
        view.configureDropShadow()
        view.configureContent(body: text)
        view.button = nil
        SwiftMessages.show(view: view)
    }

    func sendInAppNotification(_ profile: ProfileModel, title: String, body: String) {
        PhotoManager.sharedInstance.getAvatarImageFor(profile.uuid, size: 100) { (profileImage) in
            var image = UIImage()
            
            if let profileImage = profileImage {
                let iconImage = Utils.imageWithImage(profileImage, scaledToSize: CGSize(width: 50, height: 50))
                if let circularIconImage = iconImage.circle {
                    image = circularIconImage
                } else {
                    image = iconImage
                }
            }
            
            let view = MessageView.viewFromNib(layout: .CardView)
            view.configureTheme(.info)
            view.configureDropShadow()
            
            view.button?.isHidden = true
            
            view.configureContent(title: title, body: body, iconImage: image)
            SwiftMessages.show(view: view)
        }
    }
    
    fileprivate func showInAppNotification(_ title:String, body:String, iconImage:UIImage?, tapHandler:((_ view:BaseView) -> Void)? = nil) {
        var image = UIImage()

        if let iconImage = iconImage {
            let iconImageResized = Utils.imageWithImage(iconImage, scaledToSize: CGSize(width: 50, height: 50))
            if let circularIconImage = iconImageResized.circle {
                image = circularIconImage
            } else {
                image = iconImageResized
            }
        }
        
        let notificationView = MessageView.viewFromNib(layout: .MessageView)
        notificationView.configureTheme(.info)
        notificationView.configureDropShadow()
        
        notificationView.bodyLabel?.font = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: ToucheApp.Fonts.Sizes.medium)!
        notificationView.bodyLabel?.textColor = UIColor.white
        notificationView.backgroundColor = UIColor(red:0.14, green:0.14, blue:0.14, alpha:1.0) // #232323
        
        notificationView.button?.isHidden = true
        
        notificationView.tapHandler = tapHandler
        
        notificationView.configureContent(title: title, body: body, iconImage: image)
        SwiftMessages.show(view: notificationView)
    }
    
    fileprivate func sendPushNotification(_ profile: ProfileModel, userUUID: String, text: String) {
        if let endpoint = profile.endpointArn {
            AmazonSNSManager.sharedInstance.sendPush(text, userUUID: userUUID, endpointArn: endpoint)
        }
    }
    
}
