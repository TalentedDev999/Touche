//
//  FirebaseKeywordManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 26/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import Firebase

class FirebaseKeywordManager {

    // MARK: - Properties
    
    static let sharedInstance = FirebaseKeywordManager()
    
    struct Database {
        struct Nodes {
            static let keywords = "keywords"
            static let profile = "profile"
        }

        struct Profile {
            static let keyword = "keyword"
            
            struct KeywordType {
                static let you = "you"
                static let me = "me"
                static let like = "like"
                static let dislike = "dislike"
            }
        }
    }

    fileprivate let keywordsRef: DatabaseReference
    fileprivate let profileRef: DatabaseReference

    fileprivate init() {
        keywordsRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.keywords)
        keywordsRef.keepSynced(true)
        profileRef = FirebaseManager.sharedInstance.getDatabaseReference(Database.Nodes.profile)
    }
    
    // MARK: - Helper Methods
    
    func getTypeFromTag(_ tag: Int) -> String? {
        switch tag {
        case 0:
            return Database.Profile.KeywordType.me
        case 1:
            return Database.Profile.KeywordType.you
        case 2:
            return Database.Profile.KeywordType.like
        case 3:
            return Database.Profile.KeywordType.dislike
        default:
            return nil
        }
    }
    
    // MARK: - Read Methods

    func getKeywordsList(_ completion: @escaping (DataSnapshot?) -> Void) {
        keywordsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                completion(snapshot)
            } else {
                completion(nil)
            }
        })
    }

    func getKeywordsForUser(_ uuid: String, completion: @escaping (DataSnapshot?) -> Void) {
        profileRef.child(uuid).child(Database.Profile.keyword).observeSingleEvent(of: .value, with:  { (snapshot) in
            if snapshot.exists() {
                completion(snapshot)
            } else {
                completion(nil)
            }
        })
    }


    // MARK: - Write Methods
    
    func setKeyword(_ keyword: String, type: String) {
        if let uuid = UserManager.sharedInstance.toucheUUID {
            let value = [keyword: ServerValue.timestamp()]
            profileRef.child(uuid).child(Database.Profile.keyword).child(type).updateChildValues(value)
            
            // Consume
            let productId = FirebaseBankManager.ProductIds.KeywordAdded
            FirebaseBankManager.sharedInstance.consume(productId)
            
            // Log
            AnalyticsManager.sharedInstance.logEvent(productId, withTarget: keyword)
        } else {
            print("Error setting keyword, UUID not found")
        }
    }
    
    func removeKeyword(_ keyword: String, type: String) {
        if let uuid = UserManager.sharedInstance.toucheUUID {
            profileRef.child(uuid).child(Database.Profile.keyword).child(type).child(keyword).removeValue()
            
            // Consume
            let productId = FirebaseBankManager.ProductIds.KeywordAdded
            FirebaseBankManager.sharedInstance.consume(productId)
            
            // Log
            AnalyticsManager.sharedInstance.logEvent(productId, withTarget: keyword)
        } else {
            print("Error removing keyword, UUID not found")
        }
    }

    
}
