//
//  FirebaseBankManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/23/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import Firebase

class FirebaseBankManager {

    struct ProductIds {
        static let Bubble = "BUBBLE"
        static let ProfileSeen = "PROFILE_SEEN"
        static let PushNotification = "PUSH_NOTIFICATION"
        static let StartConversation = "START_CONVERSATION"
        static let ChatMessage = "CHAT_MESSAGE"
        static let PictureMessage = "PICTURE_MESSAGE"
        static let Like = "LIKE"
        static let Unlike = "UNLIKE"
        static let Hide = "HIDE"
        static let Unhide = "UNHIDE"
        static let Block = "BLOCK"
        static let Unblock = "UNBLOCK"
        static let MutualLike = "MUTUAL_LIKE"
        static let ZoomPhoto = "ZOOM_PHOTO"
        static let KeywordAdded = "KEYWORD_ADDED"
        static let KeywordRemoved = "KEYWORD_REMOVED"
    }

    struct BankDatabase {

        struct Nodes {
            static let bank = "bank"
            static let product = "product"
            static let balance = "balance"
        }

    }

    static let sharedInstance = FirebaseBankManager()

    fileprivate var bankRef: DatabaseReference?
    fileprivate var productRef: DatabaseReference

    fileprivate var usage = 0 {
        didSet {
            let usageDidChangeEvent = EventNames.Bank.usageDidChange
            MessageBusManager.sharedInstance.postNotificationName(usageDidChangeEvent, object: ["usage": self.usage] as AnyObject)
        }
    }

    fileprivate var priceTable = [String: Int]()

    fileprivate var hasNotificationBeenSent = false

    init() {

        productRef = Database.database().reference().child(BankDatabase.Nodes.product)
        //productRef.keepSynced(true)

        productRef.observe(.childAdded, with: {
            (snapshot) in
            if let productId = snapshot.value as? Int {
                self.priceTable[snapshot.key] = productId
            }
        })

        productRef.observe(.childChanged, with: {
            (snapshot) in
            if let productId = snapshot.value as? Int {
                self.priceTable[snapshot.key] = productId
            }
        })

        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            bankRef = Database.database().reference().child(BankDatabase.Nodes.bank).child(toucheUUID)
            // subscribe to the firebase bank
            // on each event adjust the usage member variable

            bankRef?.observe(.childAdded, with: {
                (snapshot) in
                if let balance = snapshot.value as? Int {
                    self.usage = balance
                }
            })

            bankRef?.observe(.childChanged, with: {
                (snapshot) in
                if let balance = snapshot.value as? Int {
                    self.usage = balance
                }
            })
        }


    }

    func getUsage() -> Int {
        return usage
    }


    func consume(_ productId: String) -> Bool {
        var amount = 1
        if let price = priceTable[productId] {
            amount = price
        }
        return consume(amount)
    }

    fileprivate func consume(_ amount: Int) -> Bool {
        if isOverLimit(amount) {
            if (!hasNotificationBeenSent) {
                hasNotificationBeenSent = true
                // send an event to display the upgrade popover
                MessageBusManager.sharedInstance.postNotificationName(EventNames.Bank.overLimitEvent)
                resetUsage()
            }
            return true
        }
        commitTx(amount)
        return true
    }

    func resetUsage() {
        hasNotificationBeenSent = false
        bankRef?.runTransactionBlock({
            (currentData: MutableData) -> TransactionResult in
            if var bankNode = currentData.value as? [String: Int] {
                bankNode["balance"] = 0
                currentData.value = bankNode
            }
            return TransactionResult.success(withValue: currentData)
        }) {
            (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    fileprivate func isOverLimit(_ amount: Int) -> Bool {
        return (usage + amount) > 500

        // if the (current usage + amount) > limit, then you are over limit
        // get the limit from the remote config
//        if let defaultUsageLimit = FirebaseRemoteConfigManager.sharedInstance.getNumberValueFor(FirebaseRemoteConfigManager.Keys.defaultUsageLimit) {
//            let overUsageLimit = Int(defaultUsageLimit)
//            return (usage + amount) > overUsageLimit
//        }
//        return false
    }

    fileprivate func commitTx(_ amount: Int) {

        //self.usage += amount

        // add the amount to the existing usage amount in a firebase transaction

        //let balance = usage + amount
        //bankRef.child(Database.Nodes.balance).setValue(balance)

        bankRef?.runTransactionBlock({
            (currentData: MutableData) -> TransactionResult in
            if var bankNode = currentData.value as? [String: Int] {
                if var balance = bankNode["balance"] as? Int {
                    balance += amount
                    bankNode["balance"] = balance
                }
                currentData.value = bankNode
                return TransactionResult.success(withValue: currentData)
            } else {
                currentData.value = ["balance": 0] // set the balance to 0 if it doesn't exist
            }
            return TransactionResult.success(withValue: currentData)
        }) {
            (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

}
