//
//  User.swift
//  Touche-ios
//
//  Created by Lucas Maris on 18/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class ToucheUser: NSObject {
        
    struct LocationCoordinate {
        var latitude:Float?
        var longitude:Float?
    }
    
    struct ToucheStructure {
        var objectId:String?
        var location = LocationCoordinate()
        var pic:String?
        var seen:String?
    }
    
    var userData: ToucheStructure?
    
    // MARK: Constructors
    
    override init() {
        super.init()
        
        userData = ToucheStructure()
    }
    
    init(WithAlgoliaJson:JSON) {
        super.init()
        
        updateAlgoliaData(WithAlgoliaJson)
    }
    
    // MARK: Methods
    
    func updateAlgoliaData(_ json:JSON) {

        print("I AM A DEPRECATED FUNCTION THAT SHOULD BE DELETED!")

        if userData == nil {
            userData = ToucheStructure()
        }
        
    }
    
    // MARK: ATLParticipant Delegate
    
    var userID:String? {
        get {
            if let id = userData?.objectId {
                return id
            }
            return nil
        }
        set {
            if let id = newValue {
                getAvatarNameFor(id)
            }
        }
    }
    
    
    // MARK: ATLAvatarItem Delegate
    
    var avatarImageURL: URL? {
        get {
            if let picUuid = userData?.pic, let userUUID = self.userID {
                return PhotoManager.sharedInstance.getPhotoURLFromName(picUuid, userUuid: userUUID, size: 300, centerFace: true, flip: true)
            }
            return nil
        }
    }
    
    var avatarImage: UIImage? {
        get {
            if avatarImg?.image == nil {
                if let imgURL = avatarImageURL {
                    avatarImg?.af_setImage(withURL: imgURL)

                }
            }
            
            return avatarImg?.image
        }
    }
    
    // MARK: Helper propertie for avatarImage
    
    fileprivate var avatarImg:UIImageView?

    
    // MARK: - USER PROFILE IMAGE
    fileprivate var picUuid:String? {
        didSet {
            avatarURL = PhotoManager.sharedInstance.getPhotoURLFromName(picUuid!, userUuid: self.userID!, size: 300)
        }
    }
    
    fileprivate var avatarURL:URL? {
        didSet {
            avatarImageView = UIImageView()

            if let url = avatarURL {
                avatarImageView!.af_setImage(withURL: url,
                        completion: { response in
                            if let image: UIImage = response.result.value {
                                self.avatarImageView?.image = image
                            }
                        })
            }
        }
    }

    fileprivate var avatarImageView:UIImageView?

    fileprivate func getAvatarNameFor(_ userID:String) {
        FirebasePeopleManager.sharedInstance.getProfilePic(userID) { (picUuid) in
            if picUuid != nil {
                self.picUuid = picUuid!
            }
        }
    }
    
    func getAvatarName() -> String? {
        return picUuid
    }
    
    func getAvatarURL() -> URL? {
        if let url = avatarURL {
            return url
        }
        return nil
    }
    
    func getAvatarImage() -> UIImage? {
        if let imageView = avatarImageView {
            return imageView.image
        }
        else {
            return nil
        }
    }
}
