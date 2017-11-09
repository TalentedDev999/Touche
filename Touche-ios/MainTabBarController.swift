//
//  MainTabBarController.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/4/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {

    // MARK: Properties

    struct ItemProperties {
        static let color = UIColor.white
        static let size = CGSize(width: 35, height: 35)
    }

    struct ItemNames {
        static let people = "People"
        static let chat = "Chat"
        static let profile = "Profile"
        static let photos = "Photos"
        static let settings = "Settings"
        static let upgrade = "Upgrade"
    }
    
    struct TabBarItems {
        var people: UITabBarItem? {
            didSet {
                let image = UIImage(named: ToucheApp.Assets.TabBarImages.people)
                let selectedImage = UIImage(named: ToucheApp.Assets.TabBarImages.peopleSelected)
                people?.image = image
                people?.selectedImage = selectedImage
                people?.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
            }
        }
        
        var chat: UITabBarItem? {
            didSet {
                let image = UIImage(named: ToucheApp.Assets.TabBarImages.chat)
                let selectedImage = UIImage(named: ToucheApp.Assets.TabBarImages.chatSelected)
                chat?.image = image
                chat?.selectedImage = selectedImage
                chat?.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
            }
        }

        var profile: UITabBarItem? {
            didSet {
                let image = UIImage(icon: .FAUser, size: CGSize(width: 40, height: 40))
                let selectedImage = UIImage(icon: .FAUser, size: CGSize(width: 45, height: 45))
                profile?.image = image
                profile?.selectedImage = selectedImage
                profile?.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
            }
        }

        var photos: UITabBarItem? {
            didSet {
                let image = UIImage(named: ToucheApp.Assets.TabBarImages.photos)
                let selectedImage = UIImage(named: ToucheApp.Assets.TabBarImages.photosSelected)
                photos?.image = image
                photos?.selectedImage = selectedImage
                photos?.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
            }
        }

        var settings: UITabBarItem? {
            didSet {
                let image = UIImage(named: ToucheApp.Assets.TabBarImages.settings)
                let selectedImage = UIImage(named: ToucheApp.Assets.TabBarImages.settingsSelected)
                settings?.image = image
                settings?.selectedImage = selectedImage
                settings?.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
            }
        }

        var upgrade: UITabBarItem? {
            didSet {
                let image = UIImage(named: ToucheApp.Assets.TabBarImages.upgrade)
                let selectedImage = UIImage(named: ToucheApp.Assets.TabBarImages.upgradeSelected)
                upgrade?.image = image
                upgrade?.selectedImage = selectedImage
                upgrade?.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
            }
        }
    }

    var tabBarItems = TabBarItems()
    
    fileprivate var peopleController:UIViewController?
    fileprivate var photosController:UIViewController?
    fileprivate var chatController:UIViewController?
    fileprivate var profileController:UIViewController?
    fileprivate var settingsController:UIViewController?

    // MARK: Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Background color
        // Grey
        //tabBar.barTintColor = UIColor(red: 35/255, green: 35/255, blue: 35/255, alpha: 35/255)
        // Blue
        tabBar.barTintColor = UIColor(red: 6/255, green: 25/255, blue: 35/255, alpha: 35/255)

        // Selected color
        tabBar.tintColor = UIColor.white

        // Selection bar color
        let selectionColor = Utils.redColorTouche
        
        tabBar.selectionIndicatorImage = UIImage().createTabBarSelectionIndicator(selectionColor, size: CGSize(width: tabBar.frame.width/CGFloat(5), height: tabBar.frame.height), lineWidth: 2.0)

        initTabBarItems()

        registerForEvents()
    }
    
    // MARK: Initializers
    
    func initTabBarItems() {
        let peopleStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.people, bundle: nil)
        peopleController = peopleStoryboard.instantiateViewController(withIdentifier: ToucheApp.NavigationViewControllerNames.people)
        //peopleController = //SwipeViewController()
        tabBarItems.people = peopleController!.tabBarItem
        addChildViewController(peopleController!)

        let photosStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.photos, bundle: nil)
        photosController = photosStoryboard.instantiateViewController(withIdentifier: ToucheApp.NavigationViewControllerNames.photos)
        tabBarItems.photos = photosController!.tabBarItem
        addChildViewController(photosController!)

        //let chatStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.chat, bundle: nil)
        //chatController = chatStoryboard.instantiateViewController(withIdentifier: ToucheApp.NavigationViewControllerNames.chat)
        chatController = UIStoryboard(name: "Chat", bundle: Bundle.main).instantiateViewController(withIdentifier: "chatNavigationController")
        tabBarItems.chat = chatController!.tabBarItem
        addChildViewController(chatController!)

        let profileStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.profile, bundle: nil)
        profileController = profileStoryboard.instantiateViewController(withIdentifier: ToucheApp.NavigationViewControllerNames.profile)
        tabBarItems.profile = profileController!.tabBarItem
        addChildViewController(profileController!)

//        let upgradeStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.upgrade, bundle: nil)
//        let upgradeController = upgradeStoryboard.instantiateViewControllerWithIdentifier(ToucheApp.NavigationViewControllerNames.upgrade)
//        tabBarItems.upgrade = upgradeController.tabBarItem
//        addChildViewController(upgradeController)

        let settingsStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.settings, bundle: nil)
        settingsController = settingsStoryboard.instantiateViewController(withIdentifier: ToucheApp.NavigationViewControllerNames.settings)

        tabBarItems.settings = settingsController!.tabBarItem
        addChildViewController(settingsController!)
    }

    func registerForEvents() {
        let gotoPhotosEvent = EventNames.MainTabBar.gotoPhotos
        let gotoPhotosSelector = #selector(MainTabBarController.gotoPhotos)
        
        let conversationsRetrievedEvent = EventNames.Chat.Conversations.wereRetrieved
        let totalUnreadMsgsDidChangeEvent = EventNames.Chat.UnreadMessages.totalUnreadMessagesDidChange
        
        let conversationsRetrievedSelector = #selector(MainTabBarController.conversationsRetrieved)
        let totalUnreadMsgsDidChangeSelector = #selector(MainTabBarController.unreadMsgDidChange)
        
        MessageBusManager.sharedInstance.addObserver(self, selector: gotoPhotosSelector, name: gotoPhotosEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: conversationsRetrievedSelector, name: conversationsRetrievedEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: totalUnreadMsgsDidChangeSelector, name: totalUnreadMsgsDidChangeEvent)
    }

    // MARK: Selectors

    func conversationsRetrieved() {
        tabBarItems.chat?.isEnabled = true
    }

    func unreadMsgDidChange() {
        var totalUnreadMsgs:Int = 0
        
        for unreadMsg in FirebaseChatManager.sharedInstance.unreadMessages {
            totalUnreadMsgs += unreadMsg.1
        }
        
        if totalUnreadMsgs == 0 {
            tabBarItems.chat?.badgeValue = nil
        } else {

            SoundManager.sharedInstance.playSound(SoundManager.Sounds.mainMenuLetter)

            if #available(iOS 10.0, *) {
                tabBarItems.chat?.badgeColor = ToucheApp.redColor
                tabBarItems.chat?.badgeValue = String(totalUnreadMsgs)
            } else {
                // Fallback on earlier versions
                setBadges([0, 0, totalUnreadMsgs, 0, 0])
            }
        }

        // set the badge to the actual number
        UIApplication.shared.applicationIconBadgeNumber = totalUnreadMsgs
        
        print("Unread Msg did change \(totalUnreadMsgs)")
    }
    
    func gotoPhotos() {
        if let pvc = photosController {
            selectedViewController = pvc
        }
    }
    
}
