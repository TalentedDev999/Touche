//
// Created by Lucas Maris on 1/24/17.
// Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import PopupDialog
import SwiftyJSON
import Alamofire
import AlamofireImage
import UIKit
import JSQWebViewController
import SDCAlertView
import Mapbox

class PopupManager: NSObject, MGLMapViewDelegate {

    // MARK: - Properties

    static let sharedInstance = PopupManager()

    open var isAlreadyShowing: Bool = false

    fileprivate var popup: PopupDialog = PopupDialog(title: "", message: "")
    fileprivate var popupId: String = ""

    fileprivate var annotationImages: [String: MGLAnnotationImage] = [:]


    func initialize() {
//        Utils.delay(10) {
//            Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(PopupManager.displayNextPopup), userInfo: nil, repeats: true)
//            PopupManager.sharedInstance.displayNextPopup()
//        }
    }

    @objc func broadcastPopupEvent() {
        print("broadcasting popup event...")
        let popupEvent = EventNames.Popup.showPopup
        MessageBusManager.sharedInstance.postNotificationName(popupEvent)
    }

    @objc func displayNextPopup(completion: @escaping () -> Void) {

        let lat = GeoManager.sharedInstance.currentLocation?.coordinate.latitude
        let lng = GeoManager.sharedInstance.currentLocation?.coordinate.longitude

        let pre = Locale.preferredLanguages[0]

        let version = UserManager.sharedInstance.version()

        // ask the server side what is the next popup to show
        if let latitude = lat, let longitude = lng {
            AWSLambdaManager.sharedInstance.getPopup(latitude, lon: longitude, locale: pre, version: version, completion: {
                (result, exception, error) in

                // parse result
                print(result)

                if result != nil {
                    let jsonResult = JSON(result!)

                    let popups = jsonResult["popups"].arrayValue

                    if let popup = popups.first {

                        self.popupId = popup["id"].stringValue;

                        if var vc = UIApplication.shared.keyWindow?.rootViewController {
                            while let presentedViewController = vc.presentedViewController {
                                vc = presentedViewController
                            }

                            // the sound could be customized
                            if nil != popup["sound"] {
                                SoundManager.sharedInstance.playSound(popup["sound"].stringValue)
                            } else {
                                SoundManager.sharedInstance.playSound(SoundManager.Sounds.bottleOpen)
                            }

                            // todo: the type of popup could be customized


                            self.displayGenericPopup(
                                    viewController: vc,
                                    title: popup["title"].stringValue,
                                    message: popup["message"].stringValue,
                                    image: nil,
                                    okButtonText: popup["okButtonText"].stringValue,
                                    cancelButtonText: popup["cancelButtonText"].stringValue,
                                    okcompletion: {
                                        SoundManager.sharedInstance.playSound(SoundManager.Sounds.textboxClose)
                                        self.executeAction(popup["okButtonAction"].dictionaryValue, vc: vc)

                                        print("pressed ok")

                                        AnalyticsManager.sharedInstance.logEvent("POPUP_\(self.popupId.uppercased())", withTarget: "1")
                                        FirebasePeopleManager.sharedInstance.markPopupAsAccepted(self.popupId)
                                        completion()
                                    },
                                    cancelcompletion: {
                                        SoundManager.sharedInstance.playSound(SoundManager.Sounds.textboxComplete)
                                        self.executeAction(popup["cancelButtonAction"].dictionaryValue, vc: vc)

                                        AnalyticsManager.sharedInstance.logEvent("POPUP_\(self.popupId.uppercased())", withTarget: "0")

                                        print("pressed cancel")
                                        FirebasePeopleManager.sharedInstance.markPopupAsDeclined(self.popupId)
                                        completion()
                                    }
                            )

                        }

                    } else {
                        completion()
                    }

                }


            })

        }

    }

    func simplePopup(_ title: String,
                     okButtonText: String) {
//        self.simplePopup(title: title, okButtonText: okButtonText, okCompletion: {
//
//        }, cancelCompletion: {
//
//        })
    }

    func simplePopup(_ title: String,
                     message: String? = nil,
                     okButtonText: String,
                     cancelButtonText: String? = nil,
                     okcompletion: @escaping () -> Void,
                     cancelcompletion: @escaping () -> Void) {

//        let alert = AlertController(title: title, message: message, preferredStyle: .Alert)
//
//        alert.actionLayout = .Vertical
//
//        if let cancelButtonText = cancelButtonText {
//            alert.addAction(AlertAction(title: cancelButtonText, style: .Default) { (action) in
//                cancelCompletion()
//            })
//        }
//
//        alert.addAction(AlertAction(title: okButtonText, style: .Preferred) { (action) in
//            okCompletion()
//        })
//        alert.present()

        if var vc = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = vc.presentedViewController {
                vc = presentedViewController
            }
            popupId = "modal"
            //displayGenericPopup(viewController: vc, title: title, message: message, image: nil, okButtonText: okButtonText, cancelButtonText: cancelButtonText, okCompletion: okCompletion, cancelCompletion: cancelCompletion)
        }
    }


    func displayGenericPopup(viewController: UIViewController,
                             title: String,
                             message: String?,
                             image: UIImage?,
                             okButtonText: String,
                             cancelButtonText: String?,
                             okcompletion: @escaping () -> Void,
                             cancelcompletion: @escaping () -> Void) {

        if let image = image {
            popup = PopupDialog(title: title, message: message, image: image, buttonAlignment: .horizontal, transitionStyle: .bounceUp, gestureDismissal: false)
        } else {
            popup = PopupDialog(title: title, message: message, buttonAlignment: .horizontal, transitionStyle: .bounceUp, gestureDismissal: false)
        }

        if let cancelButtonText = cancelButtonText {
            let cancelButton = CancelButton(title: cancelButtonText) {
                self.isAlreadyShowing = false
                cancelcompletion()
            }
            popup.addButton(cancelButton)
        }

        let okButton = DefaultButton(title: okButtonText) {
            self.isAlreadyShowing = false
            okcompletion()
        }
        popup.addButton(okButton)

        hairAndMakeup()

        if isAlreadyShowing {
            popup.dismiss()
        }

        viewController.present(popup, animated: true, completion: nil)

        isAlreadyShowing = true
    }

    func hairAndMakeup() {
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
    }

    func showProfile(_ uuid: String, image: UIImage, vc: UIViewController) {

        let profileStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.profile, bundle: nil)

        if let profileDetailVC = profileStoryboard.instantiateViewController(withIdentifier: ToucheApp.ViewControllerNames.profileDetailVC) as? ProfileDetailVC {

            FirebasePeopleManager.sharedInstance.getProfile(uuid) { (profile) in
                if let profile = profile {
                    //profileDetailVC.peopleVC = vc
                    profileDetailVC.profile = profile
                    profileDetailVC.isMainUserProfile = false

                    profileDetailVC.profilePic = image

                    Utils.executeInMainThread({
                        vc.navigationController?.present(profileDetailVC, animated: true, completion: nil)
                    })
                }
            }

            // Consume
            let productId = FirebaseBankManager.ProductIds.ProfileSeen
            FirebaseBankManager.sharedInstance.consume(productId)

            // Log Profile Seen
            AnalyticsManager.sharedInstance.logEvent(productId, withTarget: uuid)

            // add to viewed lists
            FirebasePeopleManager.sharedInstance.view(uuid)
        }

    }

    fileprivate func executeAction(_ actionDictionary: [String: JSON], vc: UIViewController) {

        if let actionObj: JSON = actionDictionary["action"], let paramsObj = actionDictionary["params"] {

            let action = actionObj.stringValue
            let params = paramsObj.dictionaryValue

            switch action {
            case "open_url":
                if let urlObj = params["url"] {
                    if let checkURL = URL(string: urlObj.stringValue) {
                        let controller = WebViewController(url: checkURL)
                        let nav = UINavigationController(rootViewController: controller)
                        controller.displaysWebViewTitle = false
                        controller.title = ""
                        vc.present(nav, animated: true, completion: nil)
                    } else {
                        print("invalid url")
                    }
                }
                break
            case "goto_photos":
                MessageBusManager.sharedInstance.postNotificationName(EventNames.MainTabBar.gotoPhotos)
                break
            case "goto_profile":
                if let uuidObj = params["uuid"] {
                    MessageBusManager.sharedInstance.postNotificationName(EventNames.MainTabBar.gotoProfile, object: ["uuid": uuidObj.stringValue] as AnyObject)
                }
                break
            case "goto_chat":
                if let uuidObj = params["uuid"] {
                    MessageBusManager.sharedInstance.postNotificationName(EventNames.MainTabBar.gotoChat, object: ["uuid": uuidObj.stringValue] as AnyObject)
                }
                break
            case "pixelate":
                PhotoManager.sharedInstance.pixelate = true
                break
            default:
                break
            }
        }


    }

    func showActualUpgradePopover(_ vc: UIViewController) {
        let upgradeStoryboardName = ToucheApp.StoryboardsNames.upgrade
        let upgradeStoryboard = UIStoryboard(name: upgradeStoryboardName, bundle: nil)
        let upgradePopoverName = ToucheApp.PopoverNames.upgrade
        let upgradePopoverVC = upgradeStoryboard.instantiateViewController(withIdentifier: upgradePopoverName)

        popupId = "upgrade"
        popup = PopupDialog(viewController: upgradePopoverVC, gestureDismissal: false)

        if let upvc = upgradePopoverVC as? UpgradePopoverVC {
            isAlreadyShowing = true
            upvc.popoverDialog = popup
            vc.present(popup, animated: true, completion: nil)
        }
    }

    func dismiss(_ completion: @escaping () -> Void) {
        popup.dismiss {
            completion()
        }
    }

    func showFilterPopup() {

        let advancedSearchPopoverName = "Advanced Search"
        let advancedSearchPopoverVC = AdvancedSearch(nibName: nil, bundle: nil)

        advancedSearchPopoverVC.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 100, height: UIScreen.main.bounds.height / 2)

        if var vc = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = vc.presentedViewController {
                vc = presentedViewController
            }

            popupId = "filters"
            popup = PopupDialog(viewController: advancedSearchPopoverVC, transitionStyle: .zoomIn, gestureDismissal: false)

            (advancedSearchPopoverVC as! AdvancedSearch).popup = popup

            let okBtn = DefaultButton(title: "Save".translate(), dismissOnTap: true) {
                MessageBusManager.sharedInstance.postNotificationName(EventNames.People.refresh)
            }

            popup.addButton(okBtn)

            hairAndMakeup()

            vc.present(popup, animated: true, completion: nil)
        }

    }

    func showMapPopup(_ profiles: [String: ProfileModel]) {

        if var vc = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = vc.presentedViewController {
                vc = presentedViewController
            }

            let map = MGLMapView(frame: vc.view.bounds)

            //map.setCenterCoordinate(self.hisLocation.coordinate, animated: true)

            map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            map.styleURL = MGLStyle.darkStyleURL(withVersion: 9)
            map.userTrackingMode = .follow
            map.isPitchEnabled = false
            map.isRotateEnabled = false
            map.isScrollEnabled = false
            map.isZoomEnabled = false

            map.delegate = self

            let popupView = MapPopup(frame: vc.view.frame, contentView: map)

            vc.view.addSubview(popupView)
            popupView.start()

            for profile in profiles.values {
                let point = MGLPointAnnotation()
                let coord = CLLocationCoordinate2D(geohash: profile.geohash!)
                point.coordinate = coord
                point.title = profile.uuid
                map.addAnnotation(point)

//                PhotoManager.sharedInstance.getAvatarImageFor(profile.uuid, placeholderImage: UIImage(named: ToucheApp.Assets.defaultImageName)!.circle!) { (imageHim) in
//                    if let image = imageHim {
//                        if let circle = image.dot {
//                            self.annotationImages[profile.uuid] = MGLAnnotationImage(image: circle, reuseIdentifier: profile.uuid)
//                        }
//                    }
//                }

            }

            if let annotations = map.annotations {
                map.showAnnotations(annotations, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: false)
            }

        }

    }

    @objc internal func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let title = annotation.title {
            return self.annotationImages[title!]
        }
        return nil
    }

    @objc internal func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return false
    }


}

