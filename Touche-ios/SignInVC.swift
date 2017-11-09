//
//  SignInVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class SignInVC: UIViewController {
    
    // MARK: Properties
    
    fileprivate struct Segues {
        static let showLogin = "Show Login"
    }
    
    fileprivate var areServicesAvailable = false
    fileprivate var isLocationAvailable = false

    var moviePlayer: MPMoviePlayerController?
    
    @IBOutlet var errorLabel: UILabel! {
        didSet {
            let loadingMsg = "🕐"
            let loadingMsgLocalized = Utils.localizedString(loadingMsg)
            errorLabel.text = loadingMsgLocalized
        }
    }
    
    // MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playVideo()
        CoreLocationManager.sharedInstance.initialize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startListenNotifications()
        
        // Check the internet connection
        if ReachabilityManager.isConnectedToNetwork() {
            LoginManager.getCognitoIdentity()
            
            // Without this the ProvisioningProfile Singleton is empty
            // Provisioning Profile is filled up only on real device
//            ProvisioningProfileParser() {
//                // Init Analytics
//                AnalyticsManager.sharedInstance.initialize()
//
//                if ProvisioningProfile.sharedProfile.isDebug {
//                    print("Debug mode")
//                } else {
//                    print("Production mode")
//                }
//            }
            
            // Subscribe to in app purchases for receive auto renews
            IAPManager.sharedInstance.initialize()
        } else {
            let errorConnectionMsg = "Please check your internet connection or try again later"
            let errorConnectionMsgLocalized = Utils.localizedString(errorConnectionMsg)
            errorLabel.text = errorConnectionMsgLocalized
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopListenNotifications()
    }
    
    deinit {
        print("SignInVC deInit")
    }
    
    fileprivate func startListenNotifications() {
        let locationAuthWhenInUseEvent = EventNames.Location.AuthorizationChanged.authorizedWhenInUsed
        let locationAuthChangeToWhenInUseSelector = #selector(SignInVC.locationServicesAvailable)
        
        let newLocationAvailableEvent = EventNames.Location.newLocationAvailable
        let newLocationAvailableSelector = #selector(SignInVC.newLocationAvailable)
        
        let servicesAvailableEvent = EventNames.Login.services_available
        let servicesAvailableSelector = #selector(SignInVC.servicesAvailable)
        
        let dontAllowLocationEvent = EventNames.Location.Dialog.dontAllow
        let dontAllowLocationSelector = #selector(SignInVC.tapOnDontAllow)
        
        MessageBusManager.sharedInstance.addObserver(self, selector: locationAuthChangeToWhenInUseSelector, name: locationAuthWhenInUseEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: servicesAvailableSelector, name: servicesAvailableEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: newLocationAvailableSelector, name: newLocationAvailableEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: dontAllowLocationSelector, name: dontAllowLocationEvent)
    }
    
    fileprivate func stopListenNotifications() {
        MessageBusManager.sharedInstance.removeObserver(self)
    }
    
    /*
     * TODO: Check if the user has logged in with any login options
     * If not show login else show people scrren
     */
    fileprivate func shouldShowLogin() {
        // todo: return an error if notifications are disabled
        registerForNotifications()

        //showPeople()
    }
    
    /*
     * Register for notifications
     * Manage results in AppDelegate
     */
    fileprivate func registerForNotifications() {
        let ntfTypes:UIUserNotificationType = [.alert, .badge, .sound];
        let ntfSettings = UIUserNotificationSettings(types: ntfTypes, categories: nil)
        UIApplication.shared.registerUserNotificationSettings(ntfSettings)
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Selector
    
    func locationServicesAvailable() {
        print("Location Authorization changed to When In Use")
        isLocationAvailable = true
        CoreLocationManager.sharedInstance.updatingLocation = true
    }
    
    func newLocationAvailable() {
        print("New Location available")
        //showPeople()
    }
    
    func servicesAvailable() {
        print("Services Available")
        areServicesAvailable = true
        //showPeople()
    }
    
    func tapOnDontAllow() {
        errorLabel.text = ""
        
        Utils.delay(2) { [unowned self] in
            if !self.isLocationAvailable {
                CoreLocationManager.sharedInstance.whenInUsePermissionsError()
            }
        }
    }

    // MARK: - Navigation
    
    /**
     * If currentLocation isn't nil show People
     */
    func showPeople() {

        registerForNotifications()
        
        if let _ = CoreLocationManager.sharedInstance.getCurrentLatitude(), let _ = CoreLocationManager.sharedInstance.getCurrentLongitude() {
            
            //if areServicesAvailable {
                let sb = UIStoryboard(name: ToucheApp.StoryboardsNames.people, bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: ToucheApp.ViewControllerNames.manTabBar)
                present(vc, animated: false, completion: nil)
                return
            //}
            
        } else {
            errorLabel.text = "Getting Location ..."
            
            CoreLocationManager.sharedInstance.currentLocation = nil
            CoreLocationManager.sharedInstance.updatingLocation = false
            CoreLocationManager.sharedInstance.updatingLocation = true
        }
    }

    func movieFinishedCallback(_ notification: Notification) {

        if let userInfo = notification.userInfo as? [String : NSNumber] {
            let reason = userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey]
            let finishReason = MPMovieFinishReason(rawValue: reason!.intValue)

            if (finishReason == MPMovieFinishReason.playbackEnded),
               let moviePlayer = notification.object as? MPMoviePlayerController {

                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish, object: moviePlayer)
                moviePlayer.view.removeFromSuperview()

                showPeople()
            }
        }
    }


    func playVideo() {

        let videoView = UIView(frame: CGRect(x: self.view.bounds.origin.x, y: self.view.bounds.origin.y, width: self.view.bounds.width, height: self.view.bounds.height))


        if let videoURL = Bundle.main.url(forResource: "splash1", withExtension: "mp4") {
            moviePlayer = MPMoviePlayerController(contentURL: videoURL)


            if let player = moviePlayer {

                NotificationCenter.default.addObserver(self, selector: #selector(movieFinishedCallback(_:)), name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish, object: player)
                player.view.frame = videoView.bounds
                player.prepareToPlay()
                player.scalingMode = .aspectFill
                player.controlStyle = .none
                player.shouldAutoplay = true

                videoView.addSubview(player.view)
            }
            self.view.addSubview(videoView)
        }

    }
    
    func showLogin() {
        performSegue(withIdentifier: Segues.showLogin, sender: nil)
    }
    
}
