//
//  FirebasePhotoManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/20/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import Firebase
import AlamofireImage

class FirebasePhotoManager {

    // MARK: - Properties

    static let sharedInstance = FirebasePhotoManager()

    fileprivate let picRef: DatabaseReference

    struct Database {

        struct Nodes {
            static let pic = "pic"
        }

        struct Pic {
            static let type = "type"
            static let hash = "hash"
            static let moderated = "moderated"
            static let moderationDate = "moderationDate"
            static let adult = "adult"
        }

    }

    fileprivate init() {
        picRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.pic)
//        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
//            picRef.child(toucheUUID).keepSynced(true)
//        }

    }

    // MARK: - Firebase Read

    func getPicsFromUser(_ userUUID: String, completion: @escaping (DataSnapshot) -> Void) {
        picRef.child(userUUID).observeSingleEvent(of: .value, with: { (snapshot) in
            completion(snapshot)
        })
    }

    func alreadyExist(_ picUUID: String, userUUUID uuid: String, completion: @escaping (Bool, DataSnapshot?) -> Void) {
        let picUUIDRef = FirebaseManager.sharedInstance.getReference(picRef, childNames: uuid, picUUID)
        picUUIDRef.observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            if snapshot.exists() {
                completion(true, snapshot)
                return
            }

            completion(false, nil)
        })
    }

    // MARK: - Firebase Write

    func addPicForUser(_ picUuid: String, uuid: String) {
        let newPicRef = picRef.child(uuid).child(picUuid)
        newPicRef.child(Database.Pic.moderated).setValue(false)
    }

    func removePic(_ picUuid: String, primary: String?) {
        if let uuid = UserManager.sharedInstance.toucheUUID {
            picRef.child(uuid).child(picUuid).removeValue()

            if primary == picUuid {
                FirebasePeopleManager.sharedInstance.removePrimaryPic(uuid)
            }
        }
    }

    func addChatPic(_ picUUID: String, imageHash: String, forUserUUID uuid: String) {
        let newChatPicRef = FirebaseManager.sharedInstance.getReference(picRef, childNames: uuid, picUUID)

        let neweChatPicValue: [String: Any] = [
                Database.Pic.moderated: false,
                Database.Pic.hash: imageHash,
                Database.Pic.type: "chat"
        ]

        FirebaseManager.sharedInstance.setValue(newChatPicRef, value: neweChatPicValue as AnyObject)
    }

    // MARK: - Firebase Observers

    func observePicAddedForUser(_ uuid: String, completion: @escaping (DataSnapshot) -> Void) {
        picRef.child(uuid).observe(.childAdded, with: { (snapshot) in
            completion(snapshot)
        })
    }

    func observePicRemovedForUser(_ uuid: String, completion: @escaping (DataSnapshot) -> Void) {
        picRef.child(uuid).observe(.childRemoved, with: { (snapshot) in
            completion(snapshot)
        })
    }

}
