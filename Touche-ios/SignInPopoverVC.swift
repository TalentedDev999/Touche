//
//  SignInPopoverVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 5/10/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

import PopupDialog
import MBProgressHUD
import SwiftMessages

class SignInPopoverVC: UIViewController {
    
    // MARK: - Properties
    
    var popoverDialog:PopupDialog?
    var containerViewController:UIViewController?
    
    var hud:MBProgressHUD?
    var hudTimeOut = 5
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Helper Methods
    
    fileprivate func loginWithFacebook() {
        guard let cvc = containerViewController else { return }
        
        FacebookManager.sharedInstance.startLoginProcces(viewController: cvc) { (success, message) in
            if success {
                print("Facebook login success")
                
                SigninPopoverManager.sharedInstance.setFacebookProfilePicAsPrimary()
                
                // Log Fb id
                if let fbId = FacebookManager.sharedInstance.getUserId() {
                    let eventFbId = AnalyticsManager.FieldsToLog.SigninFbId
                    AnalyticsManager.sharedInstance.logEvent(eventFbId, withTarget: fbId)
                }
                
                // Log Fb Email
                if let fbEmail = FacebookManager.sharedInstance.getUserEmail() {
                    let eventFbEmail = AnalyticsManager.FieldsToLog.SigninFbEmail
                    AnalyticsManager.sharedInstance.logEvent(eventFbEmail, withTarget: fbEmail)
                }
            } else {
                if let cvc = self.containerViewController {
                    SigninPopoverManager.sharedInstance.showSignInPopover(viewController: cvc)
                }
            }
        }
    }
    
    fileprivate func hudCountDown() {
        Utils.delay(1) { 
            if self.hudTimeOut > 0 {
                self.hudTimeOut -= 1
                self.hudCountDown()
            } else {
                self.popoverDialog?.dismiss()
                SigninPopoverManager.sharedInstance.closeSignInPopover()
            }
        }
    }
    
    // MARK: - Events
    
    @IBAction func tapOnFacebook() {
        // If not logging dismiss the popover to open the browser to login with fb
        if !FacebookManager.sharedInstance.isAlreadyLoggedin() {
            popoverDialog?.dismiss()
            SigninPopoverManager.sharedInstance.closeSignInPopover()
            
            // Avoid to show the popover after return from facebook login
            if let cvc = containerViewController as? PeopleVC {
                cvc.returningFromFacebook = true
            }
        } else {
            // Can't figure out how to know if the picture was approved or not
            hud = ProgressHudManager.blockCustomView(view)
            hudCountDown()
        }
        
        loginWithFacebook()
    }
    
    @IBAction func tapOnPhotos() {
        popoverDialog?.dismiss()
        SigninPopoverManager.sharedInstance.closeSignInPopover()
        
        let gotoPhotosEvent = EventNames.MainTabBar.gotoPhotos
        MessageBusManager.sharedInstance.postNotificationName(gotoPhotosEvent)
    }
    
}
