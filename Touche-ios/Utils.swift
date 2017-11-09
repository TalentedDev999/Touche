//
//  Utils.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/5/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit
import Photos
import ImageViewer
import Cupcake

class Utils {

    static let animationDuration = 0.2

    class func getRandomUUID() -> String {
        return UUID().uuidString
    }

    // MARK: - Localized String
    class func localizedString(_ key: String) -> String {
        return key
    }

    // MARK: - Navigation & View Setup

    class func navigationControllerSetup(_ navCon: UINavigationController?) {

        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.tintColor = Color("#D40265")!

        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent

        if let nc = navCon {
            nc.navigationBar.backgroundColor = UIColor.clear
            nc.navigationBar.barTintColor = Color("#000")!
            nc.navigationBar.tintColor = Color("#D40265")!
        }

    }

    class func navigationItemSetup(_ navItem: UINavigationItem?) {
//        let logoView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 42))
//
//        logoView.contentMode = UIViewContentMode.scaleAspectFit
//        logoView.clipsToBounds = true
//        logoView.image = UIImage(named: "rabbit")
//
//        navItem?.titleView = UIView(frame: logoView.bounds)
//        navItem?.titleView?.addSubview(logoView)
    }

    class func setViewBackground(_ view: UIView?) {
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: ToucheApp.bg)
        backgroundImage.contentMode = .scaleAspectFill
        view?.insertSubview(backgroundImage, at: 0)
    }

    class func setCollectionViewBackground(_ collectionView: UICollectionView?) {
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: ToucheApp.bg)
        backgroundImage.contentMode = .scaleAspectFill
        collectionView?.backgroundView = backgroundImage
    }

    // MARK: - Colors

    static let redColorTouche = UIColor(red: 255 / 255, green: 39 / 255, blue: 39 / 255, alpha: 1)
    static let darkBlueColorTouche = UIColor(red: 41 / 255, green: 58 / 255, blue: 68 / 255, alpha: 1)

    // MARK: - Screen Size

    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    static let screenCenter = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)

    // MARK: - UIView Constraints

    class func addConstraintsToView(_ view: UIView, toView: UIView, leadingConst: CGFloat, topConst: CGFloat, trailingConst: CGFloat, bottomConst: CGFloat) {

        view.translatesAutoresizingMaskIntoConstraints = false

        let constLeading = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: toView, attribute: .leading, multiplier: 1, constant: leadingConst)
        let constTop = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: toView, attribute: .top, multiplier: 1, constant: topConst)
        let constTrailing = NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: toView, attribute: .trailing, multiplier: 1, constant: trailingConst)
        let constBottom = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: toView, attribute: .bottom, multiplier: 1, constant: bottomConst)

        toView.addConstraints([constLeading, constTop, constTrailing, constBottom])
    }

    // MARK: - Authorizations Requests
    class func requestPhotoLibraryAccess(_ callback: @escaping (_ authorized: Bool) -> Void) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            callback(true)
        } else {
            PHPhotoLibrary.requestAuthorization({ (status) in
                executeInMainThread {
                    if status == .authorized {
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
            })
        }
    }

    static func delay(_ delay: Double, closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(
                deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
                execute: closure
        )
    }

    class func requestCameraAccess(_ callback: @escaping (_ authorized: Bool) -> Void) {
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == AVAuthorizationStatus.authorized {
            callback(true)
        } else {
            AVCaptureDevice.requestAccess(
                    forMediaType: AVMediaTypeVideo,
                    completionHandler: { (granted) in

                        executeInMainThread {
                            callback(granted)
                        }

                    })
        }
    }

    // MARK: - Queues

    struct Queue {
        static let userInititated = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
        static let def = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        static let background = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        static let main = DispatchQueue.main
    }

    static func executeInMainThread(_ closure: @escaping () -> Void) {
        DispatchQueue.main.async(execute: closure)
    }

    static func executeInBackgroundThread(_ closure: @escaping () -> Void) {
        Utils.Queue.background.async(execute: closure)
    }

    // MARK: - Random Position
    class func randomPositionOnCircle(_ radius: Float, center: CGPoint) -> CGPoint {
        // Random angle in [0, 2*pi]
        let theta = Float(arc4random_uniform(UInt32.max)) / Float(UInt32.max - 1) * Float(M_PI) * 2.0
        // Convert polar to cartesian
        let x = radius * cosf(theta)
        let y = radius * sinf(theta)
        return CGPoint(x: CGFloat(x) + center.x, y: CGFloat(y) + center.y)
    }


    // MARK: - Date
    class func getTimestamp() -> String {
        return String(Int64(Date().timeIntervalSince1970))
    }

    class func getTimestampMilis() -> String {
        return String(Int64(Date().timeIntervalSince1970 * 1000))
    }

    class func getDateFromTimestamp(_ timestamp: Int64) -> String {
        let timeInterval = TimeInterval(timestamp)

        let date = Date(timeIntervalSince1970: timeInterval)

        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MMM dd YYYY hh:mm"

        let dateString = dayTimePeriodFormatter.string(from: date)

        return dateString
    }

    class func getTimeElapsedFromDate(_ date: Date, toDate: Date) -> String {
//        let diff = date.difference(toDate, unitFlags: [.Year,.Month,.Day,.Hour,.Minute,.Second])
//
//        var diffString = ""
//
//        if diff.year > 0 {
//            diffString = "\(diff.year) Y"
//        }
//        else if diff.month > 0 {
//            return "\(diff.month) M"
//        }
//        else if diff.day > 0 {
//            return diffString + "\(diff.day) d"
//        }
//        else if diff.hour > 0 {
//            return diffString + "\(diff.hour) h"
//        }
//        else if diff.minute > 0 {
//            return diffString + "\(diff.minute) m"
//        }
//        else if diff.second > 0 {
//            return diffString + "\(diff.second) s"
//        }
        return "0 s"
    }

    // MARK: - Current Currency

    static func getCurrentCurrencySymbol() -> String? {
        let locale = Locale.current
        return (locale as NSLocale).object(forKey: NSLocale.Key.currencySymbol) as? String
    }

    // MARK: - Current Language

    static func getCurrentLanguage() -> String? {
        return Locale.preferredLanguages.first
    }


    // MARK: - UIImage

    class func maskImage(_ image: UIImage, withMask maskImage: UIImage) -> UIImage? {
        UIGraphicsBeginImageContext(image.size)
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        image.draw(in: rect)
        maskImage.draw(in: rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    class func scaleImage(_ image: UIImage, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    class func imageWithImage(_ image: UIImage, scaledToSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    // MARK: - UIImageView

    class func addBlurView(_ imageView: UIImageView, style: UIBlurEffectStyle) {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = imageView.bounds
        imageView.addSubview(blurEffectView)
    }

    // MARK: - Crypto

    class func getMD5HashFor(_ image: UIImage) -> String? {
        // Bad Image Quality for gain performance at the time of hashing
        guard let data = UIImageJPEGRepresentation(image, 0.10) else {
            return nil
        }
        let dataStr = String(describing: data)
        return dataStr.md5()
    }

    // MARK: - Gallery

//    class func showGallery(_ vc:UIViewController, count:Int, itemsDatasource:GalleryItemsDatasource, displacedViewDatasource: GalleryDisplacedViewsDataSource?) {
//        let index = 0
//        let galleryFrame = CGRect(x: 0, y: 0, width: 200, height: 24)
//        let headerView = CounterView(frame: galleryFrame, currentIndex: index, count: count)
//        let galleryVC = GalleryViewController(startIndex: index,
//                                              itemsDatasource: itemsDatasource,
//                                              displacedViewsDatasource: displacedViewDatasource,
//                                              configuration: GalleryConfiguration()
//        )
//
//        galleryVC.headerView = headerView
//
//        galleryVC.launchedCompletion = {
//            print("LAUNCHED")
//        }
//
//        galleryVC.closedCompletion = { print("CLOSED")
//        }
//
//        galleryVC.swipedToDismissCompletion = { print("SWIPE-DISMISSED")
//        }
//
//        galleryVC.landedPageAtIndexCompletion = { index in
//            print("LANDED AT INDEX: \(index)")
//            headerView.currentIndex = index
//        }
//
//        vc.presentImageGallery(galleryVC)
//    }

}
