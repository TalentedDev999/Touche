//
//  SigninPopoverManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/10/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import PopupDialog

class SigninPopoverManager {


    // MARK: - Properties

    static let sharedInstance = SigninPopoverManager()

    fileprivate var isAlreadyShowing = false

    // MARK: - Init Mehthods

    fileprivate init() {

    }

    // MARK: - Mehthods

    func showSignInPopover(viewController vc: UIViewController) {
        if isAlreadyShowing {
            return
        }

        let title = "Looks like you don't have a picture on your profile"
        let message = "Uploading a face pic gives you higher quality pictures"

        let popup = PopupDialog(title: title, message: message, image: UIImage(named: "selfie"))

        let buttonOne = CancelButton(title: "No Thanks.") {
            // pixelate all pics
            PhotoManager.sharedInstance.pixelate = true
            self.isAlreadyShowing = false
        }

        let buttonTwo = DefaultButton(title: "Okay, I'll upload a face picture!") {
            SoundManager.sharedInstance.playSound(SoundManager.Sounds.rat)
            let gotoPhotosEvent = EventNames.MainTabBar.gotoPhotos
            MessageBusManager.sharedInstance.postNotificationName(gotoPhotosEvent)
            self.isAlreadyShowing = false
        }

        popup.addButtons([buttonOne, buttonTwo])

        let pv = PopupDialogDefaultView.appearance()
        pv.backgroundColor = UIColor(red: 0.23, green: 0.23, blue: 0.27, alpha: 1.00)
        pv.titleFont = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: 16)!
        pv.titleColor = UIColor.white
        pv.messageFont = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: 14)!
        pv.messageColor = UIColor(white: 0.8, alpha: 1)

        let db = DefaultButton.appearance()
        db.titleFont = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: 14)!
        db.titleColor = UIColor.white
        db.buttonColor = UIColor(red: 0.25, green: 0.25, blue: 0.29, alpha: 1.00)
        db.separatorColor = UIColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1.00)

        let cb = CancelButton.appearance()
        cb.titleFont = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: 14)!
        cb.titleColor = UIColor.white
        cb.buttonColor = UIColor(red: 0.25, green: 0.25, blue: 0.29, alpha: 1.00)
        cb.separatorColor = UIColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1.00)

        vc.present(popup, animated: true, completion: nil)

        self.isAlreadyShowing = true
    }

    func closeSignInPopover() {
        isAlreadyShowing = false
    }

    func setFacebookProfilePicAsPrimary() {
        print("Set Facebook Profile Pic as Primary")

        guard let fbPicURL = FacebookManager.sharedInstance.getProfilePicURLWith(.large) else {
            return
        }
        guard let userUUID = UserManager.sharedInstance.toucheUUID else {
            return
        }

        // Try to download the facebook profile picture
        PhotoManager.sharedInstance.downloadImageAsyncFromURL(fbPicURL) { (success, fbProfileImage) in
            guard let fbProfileImage = fbProfileImage else {
                return
            }

            print("Download Facebook profile picture success")

            let picUUID = NSUUID().uuidString
            let imageURL = userUUID + "/" + picUUID

            // Try to upload the facebook profile image to S3
            PhotoManager.sharedInstance.uploadImageToS3(fbProfileImage, imageURL: imageURL, completion: { (success, message) in
                if success {
                    print("Upload picture to S3 success")
                    print("Writing to Firebase Pic \(userUUID) \(picUUID)")
                    FirebasePhotoManager.sharedInstance.addPicForUser(picUUID, uuid: userUUID)
                } else {
                    print("Upload to S3 failed with error: \(message)")
                }
            })
        }
    }

}
