//
//  FirebasePeopleManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/1/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import Firebase
import SwiftyJSON

class List {
    var collection: Set<String> = Set<String>()
}

class FirebasePeopleManager {

    // MARK: - Properties

    static let sharedInstance = FirebasePeopleManager()

    var counters = [
            "credits": 0
    ]

    struct Database {

        struct Nodes {
            static let prefs = "prefs"
            static let profile = "profile"
            static let cycles = "cycles"
        }

        struct Profile {
            static let pic = "pic"
            static let seen = "seen"
            static let popups = "popups"
            static let endpointArn = "endpointArn"
            static let poly = "poly"
            static let status = "status"
            static let within = "within"

            struct Status {
                static let Online = "online"
                static let Offline = "offline"
            }

        }

        struct Prefs {
            static let hide = "hide"
            static let hidden_by = "hidden_by"
            static let like = "like"
            static let liked_by = "liked_by"
            static let block = "block"
            static let blocked_by = "blocked_by"
            static let viewed = "viewed"
            static let viewed_by = "viewed_by"

            struct Direction {
                static let add = "add"
                static let remove = "remove"
            }

        }

        struct Cycles {
            static let numberOfCycles = "numberOfCycles"
        }

    }

    fileprivate let prefsRef: DatabaseReference
    fileprivate let profileRef: DatabaseReference
    fileprivate let cyclesRef: DatabaseReference

    fileprivate var hides = List()
    fileprivate var viewed = List()
    fileprivate var hidden_by = List()
    fileprivate var blocks = List()
    fileprivate var blocked_by = List()
    fileprivate var likes = List()
    fileprivate var liked_by = List()
    fileprivate var viewed_by = List()

    fileprivate var lists: [String: List] = [:]

    fileprivate var profileObserverHandles: [String: UInt] = [:]

    // MARK: - Methods

    func initAllLists() {

        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            //prefsRef.child(toucheUUID).keepSynced(true)
        }

//        AWSLambdaManager.sharedInstance.getLists() { result, exception, error in
//            print("Lists has executed... \(result) \(error) \(exception)")
//
//            if result != nil {
//                let jsonResult = JSON(result!)
//                self.handleListResult(jsonResult)
//            }
//
//        }
    }

    fileprivate init() {
        prefsRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.prefs)
        profileRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.profile)
        cyclesRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.cycles)

        lists = [
                Database.Prefs.hide: hides,
                Database.Prefs.like: likes,
                Database.Prefs.block: blocks,
                Database.Prefs.hidden_by: hidden_by,
                Database.Prefs.liked_by: liked_by,
                Database.Prefs.blocked_by: blocked_by,
                Database.Prefs.viewed_by: viewed_by
        ]

        setStatus(Database.Profile.Status.Online)

        initAllLists()
    }

    func fireListChangeEvent(_ listId: String, direction: String, uuid: String, timestamp: String) {
        let listChangeEventName = EventNames.List.didChange
        MessageBusManager.sharedInstance.postNotificationName(listChangeEventName, object: [
                "listId": listId,
                "direction": direction,
                "uuid": uuid,
                "timestamp": timestamp
        ] as AnyObject)
    }

    func fireProfileChangeEvent(_ uuid: String, key: String) {
        let profileChangeEventName = EventNames.Profile.didChange
        MessageBusManager.sharedInstance.postNotificationName(profileChangeEventName, object: [
                "uuid": uuid,
                "key": key
        ] as AnyObject)
    }

    func fireLifeEvent(_ uuid: String, lifeEventName: String, timestamp: String) {
        print("firing event \(lifeEventName)")
        MessageBusManager.sharedInstance.postNotificationName(EventNames.LifeEvents.didOccur, object: [
                "uuid": uuid,
                "lifeEventName": lifeEventName,
                "timestamp": timestamp
        ] as AnyObject)
    }

    func getList(_ listId: String) -> List? {
        if let list = lists[listId] {
            return list
        }
        return nil
    }

    func isUserAlreadyInLikes(_ userUUID: String) -> Bool {
        if likes.collection.contains(userUUID) {
            return true
        }
        return false
    }

    // MARK: - Read Database Methods

    func getProfile(_ userUUID: String, completion: @escaping (ProfileModel?) -> Void) {

        let userProfileRef = FirebaseManager.sharedInstance.getReference(profileRef, childNames: userUUID)

        userProfileRef.observeSingleEvent(of: DataEventType.value, with: {
            (snapshot) in
            completion(self.buildProfileModelFrom(snapshot))
        }) {
            (error) in
            completion(nil)
            print(error)
        }
    }

    func isVisibleOnPeopleView(_ uuid: String) -> Bool {
        return !self.lists[Database.Prefs.hide]!.collection.contains(uuid)
                && !self.lists[Database.Prefs.like]!.collection.contains(uuid)
                && !self.lists[Database.Prefs.block]!.collection.contains(uuid)
                && !self.lists[Database.Prefs.blocked_by]!.collection.contains(uuid)
                && uuid != UserManager.sharedInstance.toucheUUID!
    }


    fileprivate func buildProfileModelFrom(_ snapshot: DataSnapshot) -> ProfileModel? {
        guard let snapshotDict = snapshot.value as? [String: AnyObject] else {
            return nil
        }

        let uuid = snapshot.key

        let num = snapshotDict[Database.Profile.seen] as? String
        let endpointArn = snapshotDict[Database.Profile.endpointArn] as? String
        var seen: Int64 = Int64(Date().timeIntervalSince1970) // defaults to now
        let status = snapshotDict[Database.Profile.status] as? String

        if num != nil {
            seen = Int64(num!)!
        }

        let profileModel = ProfileModel(uuid: uuid, pic: snapshotDict[Database.Profile.pic] as? String, seen: seen, status: status, endpointArn: endpointArn, geohash: "")

        return profileModel
    }

    func getProfilePic(_ userUUID: String, completion: @escaping (String?) -> Void) {
        getProfile(userUUID) { (profile) in
            if let profile = profile {
                completion(profile.pic)
            } else {
                completion(nil)
            }
        }
    }

    func getPolygonDataForUser(_ userUUID: String, completion: @escaping (DataSnapshot) -> Void) {
        profileRef.child(userUUID).child(Database.Profile.within).observeSingleEvent(of: .value, with: { (snapshot) in
            completion(snapshot)
        })
    }

    // MARK: - Writing Database

    func setPrimaryPic(_ userUUID: String, primaryPic: String) {
        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            profileRef.child(toucheUUID).child(Database.Profile.pic).setValue(primaryPic)
        }
    }

    func removePrimaryPic(_ userUUID: String) {
        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            profileRef.child(toucheUUID).child(Database.Profile.pic).removeValue()
        }
    }

    func isPrimaryPicSetted(_ completion: @escaping (Bool) -> Void) {
        guard let userUUID = UserManager.sharedInstance.toucheUUID else {
            completion(false);
            return
        }
        let picNode = Database.Profile.pic
        let profilePrimaryPicRef = FirebaseManager.sharedInstance.getReference(profileRef, childNames: userUUID, picNode)

        profilePrimaryPicRef.observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            if let _ = snapshot.value as? String {
                completion(true)
                return
            }

            completion(false)
        })
    }

    func hasSeenPopup(_ popupId: String, completion: @escaping (Bool) -> Void) {
        guard let toucheUUID = UserManager.sharedInstance.toucheUUID else {
            completion(false)
            return
        }

        profileRef.child(toucheUUID).child(Database.Profile.popups).observeSingleEvent(of: .value, with: { (snapshot) in
            completion(snapshot.hasChild(popupId))
        })

    }

    func hasOkayedPopup(_ popupId: String, completion: @escaping (Bool) -> Void) {
        guard let toucheUUID = UserManager.sharedInstance.toucheUUID else {
            completion(false)
            return
        }

        profileRef.child(toucheUUID).child(Database.Profile.popups).child(popupId).child("answer").observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            if let answer = snapshot.value as? String {
                completion(answer == "1")
                return
            }

            completion(false)
        })

    }

    func markPopupAsAccepted(_ popupId: String) {
        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            profileRef.child(toucheUUID).child(Database.Profile.popups).updateChildValues([popupId: ["date": Utils.getTimestampMilis(), "answer": "1"]])
        }
    }

    func markPopupAsDeclined(_ popupId: String) {
        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            profileRef.child(toucheUUID).child(Database.Profile.popups).updateChildValues([popupId: ["date": Utils.getTimestampMilis(), "answer": "0"]])
        }
    }

    func setSeen(_ userUUID: String) {
        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            profileRef.child(toucheUUID).child(Database.Profile.seen).setValue(Utils.getTimestampMilis())
        }
    }

    func setStatus(_ status: String) {
        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            profileRef.child(toucheUUID).child(Database.Profile.status).setValue(status)
        }
    }

    func handleListResult(_ jsonResult: JSON) -> [String: Int] {

        //print(jsonResult)

        counters = [
                "mutual_likes": jsonResult["mutual_likes"].intValue,
                "like": jsonResult["like"].intValue,
                "hide": jsonResult["hide"].intValue,
                "credits": jsonResult["credits"].intValue,
                "exp": jsonResult["exp"].intValue
        ]

        // todo:

        return counters

        // reset lists and refresh from server
//        self.likes.collection.removeAll()
//        self.blocks.collection.removeAll()
//        self.hides.collection.removeAll()
//        self.viewed.collection.removeAll()
//
//        for like in jsonResult["like"].arrayObject as! [String] {
//            self.likes.collection.insert(like)
//        }
//
//        for block in jsonResult["block"].arrayObject as! [String] {
//            self.blocks.collection.insert(block)
//        }
//
//        for hide in jsonResult["hide"].arrayObject as! [String] {
//            self.hides.collection.insert(hide)
//        }
//
//        for viewed in jsonResult["viewed"].arrayObject as! [String] {
//            self.viewed.collection.insert(viewed)
//        }
    }

    func unhide(_ userUUID: String) {
        AWSLambdaManager.sharedInstance.updateLists("delete", id: "hide", uuids: [userUUID]) { result, exception, error in
            if result != nil {
                self.handleListResult(JSON(result!))
            }
        }
    }

    func hideMultiple(_ uuids: [String], completion: @escaping () -> Void) {
        AWSLambdaManager.sharedInstance.updateLists("add", id: "hide", uuids: uuids) { result, exception, error in
            if result != nil {
                self.handleListResult(JSON(result!))
            }
            completion()
        }
    }

    func hide(_ userUUID: String, completion: @escaping ([String: Int]) -> Void) {
        AWSLambdaManager.sharedInstance.updateLists("add", id: "hide", uuids: [userUUID]) { result, exception, error in
            if result != nil {
                completion(self.handleListResult(JSON(result!)))
            } else {
                completion([:])
            }
        }
    }

    func like(_ userUUID: String, completion: @escaping ([String: Int]) -> Void) {
        AWSLambdaManager.sharedInstance.updateLists("add", id: "like", uuids: [userUUID]) { result, exception, error in
            if result != nil {
                completion(self.handleListResult(JSON(result!)))
            } else {
                completion([:])
            }
        }
    }

    func dislike(_ userUUID: String, completion: @escaping () -> Void = {
    }) {
        AWSLambdaManager.sharedInstance.updateLists("add", id: "dislike", uuids: [userUUID]) { result, exception, error in
            if result != nil {
                self.handleListResult(JSON(result!))
            }
            completion()
        }
    }

    func unlike(_ userUUID: String) {
        AWSLambdaManager.sharedInstance.updateLists("delete", id: "like", uuids: [userUUID]) { result, exception, error in
            if result != nil {
                self.handleListResult(JSON(result!))
            }
        }
    }

    func block(_ userUUID: String, completion: @escaping () -> Void = {
    }) {
        AWSLambdaManager.sharedInstance.updateLists("add", id: "block", uuids: [userUUID]) { result, exception, error in
            if result != nil {
                self.handleListResult(JSON(result!))
            }
            completion()
        }
    }

    func view(_ userUUID: String) {
        AWSLambdaManager.sharedInstance.updateLists("add", id: "viewed", uuids: [userUUID]) { result, exception, error in
            if result != nil {
                self.handleListResult(JSON(result!))
            }
        }
    }

    func unblock(_ userUUID: String) {
        AWSLambdaManager.sharedInstance.updateLists("delete", id: "block", uuids: [userUUID]) { result, exception, error in
            if result != nil {
                self.handleListResult(JSON(result!))
            }
        }
    }

    func storeInProfile(_ value: String, forKey: String) {
        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            profileRef.child(toucheUUID).child(forKey).setValue(value)
        }
    }

    func getNumberOfCycles(_ completion: @escaping (Int) -> Void) {
        guard let userUUID = UserManager.sharedInstance.toucheUUID else {
            completion(0);
            return
        }
        let numberOfCycles = Database.Cycles.numberOfCycles
        let numberOfCyclesRef = FirebaseManager.sharedInstance.getReference(cyclesRef, childNames: userUUID, numberOfCycles)

        numberOfCyclesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let numberOfCycles = snapshot.value as? Int {
                completion(numberOfCycles)
                return
            }

            completion(0)
        })
    }

    func observeNumberOfCycles(_ completion: @escaping (Int?) -> Void) {
        guard let userUUID = UserManager.sharedInstance.toucheUUID else {
            return
        }
        let userCyclesRef = FirebaseManager.sharedInstance.getReference(cyclesRef, childNames: userUUID)

        userCyclesRef.observe(.childChanged, with: { (snapshot) in
            print("Number of cycles did change")
            if let numberOfCycles = snapshot.value as? Int {
                completion(numberOfCycles)
                return
            }

            completion(nil)
        })
    }

    func incrementNumberOfCycles() {
        guard let userUUID = UserManager.sharedInstance.toucheUUID else {
            return
        }
        let userCyclesRef = FirebaseManager.sharedInstance.getReference(cyclesRef, childNames: userUUID)

        userCyclesRef.runTransactionBlock({ (cycles) -> TransactionResult in
            if var cyclesNode = cycles.value as? [String: Any] {
                if var numberOfCycles = cyclesNode[Database.Cycles.numberOfCycles] as? Int {
                    numberOfCycles += 1
                    cyclesNode[Database.Cycles.numberOfCycles] = numberOfCycles
                }
                cycles.value = cyclesNode
            } else {
                cycles.value = [Database.Cycles.numberOfCycles: 1] // set to 1 if doesn't exist
            }

            return TransactionResult.success(withValue: cycles)
        }) { (error, commited, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    func unblockAll() {
        // empty blocks
        self.blocks.collection.removeAll()

        AWSLambdaManager.sharedInstance.updateLists("dump", id: "block", uuids: []) { result, exception, error in
            print("Lists has executed... \(result) \(error) \(exception)")
            if result != nil {
                self.handleListResult(JSON(result!))
            }
        }
    }

    func dumpHides(completion: @escaping ([String: Int]) -> Void) {
        AWSLambdaManager.sharedInstance.updateLists("dump", id: "hide", uuids: []) { result, exception, error in
            if result != nil {
                completion(self.handleListResult(JSON(result!)))
            } else {
                completion([:])
            }
        }
    }

    func dumpAll(completion: @escaping ([String: Int]) -> Void) {
        AWSLambdaManager.sharedInstance.updateLists("dump", id: "all", uuids: []) { result, exception, error in
            if result != nil {
                completion(self.handleListResult(JSON(result!)))
            } else {
                completion([:])
            }
        }
    }

}
