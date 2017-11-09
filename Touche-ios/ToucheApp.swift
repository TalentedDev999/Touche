//
//  ToucheApp.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit
import Cupcake
import NVActivityIndicatorView

class ToucheApp {

    // Amazon Services
    static let amazonBucket = "touche"
    static let amazonContentType = "image/jpg"

    // Location
    static let updateLocationLambdaFunctionName: String = "UpdateLocation"

    // Tags - Keywords
    static let saveProfileTagsLambdaFunctionName: String = "UpdateKeywords"

    // Imgix
    static let imgixHost = "touche.imgix.net"
    static let imgixToken = "mPWEtQIpgT93GZL7"
    // fixme: cannot be hardcoded here!!!

    static let toastDuration: Double = 3

    // Photo upload
    static let maxPhotosToUpload = 4

    // background
    static let bg = "textureRabbit"

    static let activityData = ActivityData(type: .ballPulseSync, color: Color("#D40265"))

    // App Colors

    static let mainColor = UIColor(red: 0.84, green: 0.05, blue: 0.07, alpha: 1.0)
    // #D70D12
    static let textColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
    // #FAFAFA
    static let redColor = UIColor(red: 0.66, green: 0.04, blue: 0.05, alpha: 1.0)
    // #A80B0C

    static let pinkColor = Color("#D40265")!

    // Fonts

    struct Fonts {

        static let montserratBig = Font("Montserrat-Regular,15")
        static let montserratMedium = Font("Montserrat-Light,13")
        static let montserratSmall = Font("Montserrat-Regular,10")

        struct Regular {
            static let montserrat = "Montserrat-Regular"
        }

        struct Light {
            static let montserrat = "Montserrat-Light"
        }

        struct Sizes {
            static let tiny: CGFloat = 12
            static let medium: CGFloat = 14
            static let big: CGFloat = 18
        }

    }

    // Storyboards

    struct StoryboardsNames {
        static let sigin = "SignIn"
        static let people = "People"
        static let chat = "Chat"
        static let profile = "Profile"
        static let photos = "Photos"
        static let settings = "Settings"
        static let upgrade = "Upgrade"
    }

    struct NavigationViewControllerNames {
        static let people = "peopleNVC"
        static let chat = "chatNVC"
        static let profile = "profileNVC"
        static let photos = "photosNVC"
        static let settings = "settingsNVC"
        static let upgrade = "upgradeNVC"
    }

    struct ViewControllerNames {
        static let manTabBar = "MainTabBarController"
        static let gameVC = "GameVC"
        static let profileDetailVC = "ProfileDetailVC"
        static let profileKeywordsVC = "ProfileKeywordsVC"
        static let photosCollectionVC = "PhotosCollectionVC"
    }

    struct PopoverNames {
        static let upgrade = "Upgrade popover"
        static let photoDelete = "PhotoDelete popover"
        static let signin = "Sign in popover"
    }

    struct Segues {
        static let profileDetailAction = "actionSegue"
    }

    // Labels

    struct ChatLabels {
        static let noMessages = "There are no messages =("
    }

    // Assets

    struct Assets {
        static let defaultImageName = "privateRabbit"
        static let backButtonItem = "ic_back"
        static let closeNormal = "close_normal"
        static let closeHighlighted = "close_highlighted"
        static let arrowDown = "arrowDown"
        static let splash = "splash"
        static let bubbleMark = "bubble"

        struct Keyword {
            static let me = "Person in a Mirror"
            static let you = "Clone"
            static let like = "Good Quality"
            static let dislike = "Poor Quality"
        }

        struct TabBarImages {
            static let people = "down1"
            static let peopleSelected = "down1-35"
            static let chat = "down2"
            static let chatSelected = "down2-35"
            static let photos = "down3"
            static let photosSelected = "down3-35"
            static let settings = "down4"
            static let settingsSelected = "down4-35"
            static let upgrade = "down5"
            static let upgradeSelected = "down5-35"
        }

    }

}
