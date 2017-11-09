//
//  PhotoManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit
import ImageViewer
import Alamofire
import AlamofireImage
import AWSS3
import ImgixSwift

class PhotoManager {

    static let sharedInstance = PhotoManager()


    class DiskCache: URLCache {

        private let constSecondsToKeepOnDisk = 30 * 24 * 60 * 60

        // numDaysToKeep is your own constant or hard-coded value

        override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {

            var customCachedResponse = cachedResponse
            // Set custom Cache-Control for Image-Response
            let response = cachedResponse.response as! HTTPURLResponse

            if let contentType = response.allHeaderFields["Content-Type"] as? String,
               var newHeaders = response.allHeaderFields as? [String: String], contentType.contains("image") {
                newHeaders["Cache-Control"] = "public, max-age=\(constSecondsToKeepOnDisk)"
                if let url = response.url, let newResponse = HTTPURLResponse(url: url, statusCode: response.statusCode, httpVersion: "HTTP/1.1", headerFields: newHeaders) {
                    customCachedResponse = CachedURLResponse(response: newResponse, data: cachedResponse.data, userInfo: cachedResponse.userInfo, storagePolicy: cachedResponse.storagePolicy)
                }
            }
            super.storeCachedResponse(customCachedResponse, for: request)
        }
    }

    func diskImageDownloader(diskSpaceMB: Int = 100) -> ImageDownloader {
        let diskCapacity = diskSpaceMB * 1024 * 1024
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = DiskCache(memoryCapacity: 100, diskCapacity: diskCapacity, diskPath: "toucheapp_image_disk_cache")
        let downloader = ImageDownloader(configuration: configuration)
        UIImageView.af_sharedImageDownloader = downloader
        return downloader
    }

    var downloader: ImageDownloader!

    fileprivate init() {
    }

    let blurPro: UInt = 1000


    var pixelate: Bool = false {
        didSet {
            if oldValue != pixelate {
                MessageBusManager.sharedInstance.postNotificationName(EventNames.People.refresh)
            }
        }
    }

    func checkPrimaryPic() {
        FirebasePeopleManager.sharedInstance.isPrimaryPicSetted { (result) in
            if (result) {
                self.pixelate = false
            } else {
                // and has never seen the has_facepic popup
                FirebasePeopleManager.sharedInstance.hasSeenPopup("has_facepic") { (seen) in
                    if (!seen) {
                        self.pixelate = false
                    } else {
                        self.pixelate = true
                    }
                }
            }
        }
    }

    // MARK: - Methods

    // return signed photo url

    func getAvatarImageFor(_ uuid: String, size: Int? = 300, placeholderImage: UIImage? = nil, completion: @escaping (UIImage?) -> Void) {
        FirebasePeopleManager.sharedInstance.getProfilePic(uuid) { (picUuid) in
            //print(picUuid)
            guard let picUuid = picUuid else {
                completion(nil);
                return
            }
            let imgURL = PhotoManager.sharedInstance.getPhotoURLFromName(picUuid, userUuid: uuid, size: size)

            self.downloadImageAsyncFromURL(imgURL) { (success, image) in
                if success {
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }
    }

    func getImageFromURL(_ imageURL: URL, completion: @escaping (UIImage?) -> Void) {

        self.downloadImageAsyncFromURL(imageURL) { (success, image) in
            if success {
                completion(image)
            } else {
                completion(nil)
            }
        }
    }

    func getPhotoURLFromName(_ s3Key: String, width: Int, height: Int) -> URL {
        let client = ImgixClient(host: ToucheApp.imgixHost, secureUrlToken: ToucheApp.imgixToken)

        var params: [String: String]
        params = [
                "auto": "compress",
                "h": "\(height)"
        ]

        let signedImageURL = client.buildUrl("\(s3Key)", params: params as NSDictionary)
        return signedImageURL
    }

    func getPhotoURLFromNamePopup(_ s3Key: String, width: Int, height: Int) -> URL {
        let client = ImgixClient(host: ToucheApp.imgixHost, secureUrlToken: ToucheApp.imgixToken)

        var params: [String: String]
        params = [
                "auto": "enhance",
                "h": "\(height)",
                "w": "\(width)",
                "markalign": "left,top",
                "mark": "/assets/bgRabbit.png",
                "flip": "h",
                "fit": "scale",
                "markalpha": "50",
                "markw": "\(width / 3)"
        ]

        let signedImageURL = client.buildUrl("\(s3Key)", params: params as NSDictionary)
        return signedImageURL
    }

    func getPhotoURLFromName(_ picUuid: String, userUuid: String, size: Int? = 0, width: Int? = 0, height: Int? = 0, centerFace: Bool? = true, flip: Bool? = true) -> URL {
        let client = ImgixClient(host: ToucheApp.imgixHost, secureUrlToken: ToucheApp.imgixToken)
        let picSize = size == 0 ? 300 : size!

        var params: [String: String]

        params = ["auto": "enhance", "h": "\(picSize)", "w": "\(picSize)"]

        if let w = width, let h = height {
            if w > 0 && w > 0 {
                params = ["auto": "enhance", "h": "\(h)", "w": "\(w)"]
            }
        }

        if centerFace == true {
            params["crop"] = "faces"
            params["fit"] = "facearea"
            params["facepad"] = "2"
        }

        // watermark everything
        //params["markalign"] = "center,middle"
        //params["mark"] = "/assets/bgRabbit.png"
        //params["markalpha"] = "50"
        //params["markw"] = "\(picSize / 2)"

        if flip == true {
            params["flip"] = "h"
        }

        if pixelate == true {
            params["px"] = "15"
        }

        let signedImageURL = client.buildUrl("\(userUuid + "/" + picUuid)", params: params as NSDictionary)
        return signedImageURL
    }

    func getImageURLFrom(_ userUUID: String, picUUID: String) -> URL {
        return getPhotoURLFromName(picUUID, userUuid: userUUID, size: 320, centerFace: false, flip: false)
    }

    func getImageFromName(_ picUuid: String, completion: @escaping (UIImage?) -> Void) {
        let imgURL = getPhotoURLFromName(picUuid, userUuid: UserManager.sharedInstance.toucheUUID!)

        self.downloadImageAsyncFromURL(imgURL) { (success, image) in
            if success {
                completion(image)
            } else {
                completion(nil)
            }
        }
    }

    func setImageView(_ imageView: UIImageView, withImageName picUuid: String) {
        let imgURL = getPhotoURLFromName(picUuid, userUuid: UserManager.sharedInstance.toucheUUID!)

        UIImageView().af_setImage(withURL: imgURL,
                placeholderImage: UIImage(named: ToucheApp.Assets.defaultImageName))
    }

/*
 * Try to upload a image to S3
 * If the task success: 'completion' 1st param = true; 'completion' 2nd param = nil
 * If task is cancelled or an error occur: 'completion' 1st param = false; 'completion' 2nd param = error message
 */
    func uploadImageToS3(_ image: UIImage, imageURL: String, completion: @escaping (Bool, String?) -> Void) {
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            return
        }

        let contentType = "image/jpeg"
        let tempImage = NSTemporaryDirectory() + "tempImage"
        let tempImageURL = URL(fileURLWithPath: tempImage)

        do {
            try imageData.write(to: tempImageURL)
        } catch {
            print("upload failed")
        }

        if let uploadRequest = AWSS3TransferManagerUploadRequest() {

            uploadRequest.bucket = ToucheApp.amazonBucket
            uploadRequest.contentType = contentType
            uploadRequest.key = imageURL        // Path where save the image in the bucket
            uploadRequest.body = tempImageURL   // Image to upload to the bucket

            let task = AWSS3TransferManager.default().upload(uploadRequest)
            task.continueWith { (task) -> AnyObject? in
                if task.error != nil {
                    let errorMsg = task.error?.localizedDescription
                    print("Error: uploadToS3 - \(errorMsg)")
                    completion(false, errorMsg)
                    return nil
                }

                if task.isCancelled {
                    let errorMsg = "Task was cancelled"
                    print("Error: uploadToS3 - \(errorMsg)")
                    completion(false, errorMsg)
                    return nil
                }

                if task.result != nil {
                    completion(true, nil)
                    return nil
                }

                completion(false, nil)
                return nil
            }
        }
    }

    func deleteImageFromS3(_ user: String, picUUID: String) {
        let s3 = AWSS3.default()

        if var deleteObjectRequest = AWSS3DeleteObjectRequest() {
            deleteObjectRequest.bucket = ToucheApp.amazonBucket
            deleteObjectRequest.key = user + "/" + picUUID

            s3.deleteObject(deleteObjectRequest).continueWith { (task: AWSTask) -> AnyObject? in
                if let error = task.error {
                    print("Error occurred: \(error)")
                    return nil
                }
                print("Deleted successfully.")
                return nil
            }
        }
    }

    func downloadImageAsyncFromURL(_ imageURL: URL, completion: @escaping (Bool, UIImage?) -> Void) {

        let URLRequest = Foundation.URLRequest(url: imageURL)

        donloader().download(URLRequest) { response in

            //print(response.request)
            //print(response.response)

            //debugPrint(response.result)

            if let image = response.result.value {
                completion(true, image)
            } else {
                completion(false, nil)
            }
        }

    }

    private func donloader() -> ImageDownloader {
        if let d = downloader {
            return d
        } else {
            downloader = diskImageDownloader()
            return downloader
        }
    }
}
