//
//  UserManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 21/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import Sparrow
import Tabby
import Cupcake

class PermissionsManager {

    struct ToucheView {
        let name: String
        let controller: UIViewController
        let image: String
    }

    static let sharedInstance = PermissionsManager()

    private var homeController: TabbyController?

    func arePermsAvailable() -> Bool {
        let isAvailableLocation = SPRequestPermission.isAllowPermission(SPRequestPermissionType.locationWhenInUse)
        let isAvailableNotification = SPRequestPermission.isAllowPermission(SPRequestPermissionType.notification)
        let isAvailablePhotos = SPRequestPermission.isAllowPermission(SPRequestPermissionType.photoLibrary)
        let isAvailableCamera = SPRequestPermission.isAllowPermission(SPRequestPermissionType.camera)

        if isAvailableLocation
                   && isAvailableNotification
                   && isAvailablePhotos
                   && isAvailableCamera {
            return true
        } else {
            return false
        }
    }

    func home() -> UIViewController {
        if let home = homeController {
            return home
        }
        return setupHomeController()
    }

    func setupHomeController() -> UIViewController {
        Tabby.Constant.Color.background = Color("#000")!
        Tabby.Constant.Color.selected = Color("#D40265")!
        Tabby.Constant.Behavior.labelVisibility = .invisible
        Tabby.Constant.Dimension.height = 50
        Tabby.Constant.Dimension.Indicator.position = .bottom
        Tabby.Constant.Animation.initial = .pop
        Tabby.Constant.Font.badge = ToucheApp.Fonts.montserratBig
        Tabby.Constant.Color.Badge.background = Color("#D40265")!
        Tabby.Constant.Color.Badge.border = Color("#D40265")!


        let controllers = [
                ToucheView(name: "Swipe", controller: SwipeViewController(), image: "009-playing-cards"),
                //ToucheView(name: "Bubbles", controller: UIStoryboard(name: ToucheApp.StoryboardsNames.people, bundle: nil).instantiateViewController(withIdentifier: "peopleVC"), image: "007-bubbles"),
            ToucheView(name: "Inbox", controller: UIStoryboard(name: "Chat", bundle: Bundle.main).instantiateViewController(withIdentifier: "inboxController"), image: "006-chat-bubble"),
                //ToucheView(name: "Photos", controller: UIStoryboard(name: ToucheApp.StoryboardsNames.photos, bundle: nil).instantiateViewController(withIdentifier: "PhotosCollectionVC"), image: "004-photo"),
                //ToucheView(name: "Keywords", controller: UIStoryboard(name: ToucheApp.StoryboardsNames.profile, bundle: nil).instantiateViewController(withIdentifier: ToucheApp.ViewControllerNames.profileKeywordsVC), image: "001-hash"),
            ToucheView(name: "Settings", controller: SettingsVC(), image: "005-settings-gears")
        ]


        let items: [TabbyBarItem] = controllers.map {
            let c = $0.controller
            let nc = UINavigationController(rootViewController: c)
            nc.title = $0.name

            Utils.navigationControllerSetup(nc)

            return TabbyBarItem(controller: nc, image: $0.image)
        }

        homeController = HomeController(items: items)
        homeController!.delegate = homeController as! TabbyDelegate
        homeController!.translucent = false
        homeController!.barVisible = true
        homeController!.view.frame = CGRect(x: 0, y: 0, width: Utils.screenWidth, height: Utils.screenHeight)

        let bc: Int = AppBadgeManager.sharedInstance.getAppBadgeCount()

        homeController!.setBadge(bc, "006-chat-bubble")

        return homeController!
    }
}
