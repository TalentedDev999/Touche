//
//  FirebaseIAPManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 20/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Firebase

class FirebaseIAPManager {

    // MARK: - Properties

    static let sharedInstance = FirebaseIAPManager()

    fileprivate struct IAP {

        static let ref = "inAppPurchase"

        struct Consumable {

            static let ref = "consumable"

            static let productId = "product_id"
        }

    }

    fileprivate struct IapProduct {
        static let ref = "iapProduct"
    }

    fileprivate struct IapProductData {
        static let ref = "iapProductData"
    }

    fileprivate var iapProductRef: DatabaseReference
    fileprivate var iapProductDataRef: DatabaseReference
    fileprivate var profileIAPRef: DatabaseReference?

    var subcriptionsWereReceived = false

    // MARK: - Init Methods

    fileprivate init() {
        iapProductRef = FirebaseManager.sharedInstance.getDatabaseReference(IapProduct.ref)
        iapProductDataRef = FirebaseManager.sharedInstance.getDatabaseReference(IapProductData.ref)

        setupUserRef()
    }

    // MARK: - Helper Methods

    func setupUserRef() {
        if let uuid = UserManager.sharedInstance.toucheUUID {
            profileIAPRef = FirebaseManager.sharedInstance.getDatabaseReference(FirebasePeopleManager.Database.Nodes.profile, uuid, IAP.ref)
            observeSubscription()
        }
    }


    fileprivate func deliverSubscriptionChangeEvent() {
        let subscriptionChangeEvent = EventNames.Upgrade.subscriptionDidChange
        MessageBusManager.sharedInstance.postNotificationName(subscriptionChangeEvent)
    }

    // MARK: - Methods

    func observeSubscription() {
        profileIAPRef!.observe(.childAdded, with: { (snapshot) in
            print("FirebaseIAPManager: Subscription added")
            guard let data = snapshot.value as? [String: AnyObject] else {
                return
            }
            let subscription = IAPSubscription(data: data)
            if subscription.isAValidSubscription() {

                // todo: send event

                IAPManager.sharedInstance.currentSubscription = subscription
            } else {
                print("FirebaseIAPManager: Invalid sub")
            }
        })

        profileIAPRef!.observe(.childChanged, with: { (snapshot) in
            print("FirebaseIAPManager: Subscription changed")
            guard let data = snapshot.value as? [String: AnyObject] else {
                return
            }
            let subscription = IAPSubscription(data: data)
            if subscription.isAValidSubscription() {

                // todo: send event

                IAPManager.sharedInstance.currentSubscription = subscription
            } else {
                print("FirebaseIAPManager: Invalid sub")
            }
        })
    }

    func getIAPProductsData(_ productsIdentifiers: [String], completion: @escaping ([String: ProductDataModel]?) -> Void) {
        iapProductDataRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotDict = snapshot.value as? [String: AnyObject] {
                var productsData = [String: ProductDataModel]()

                for productId in productsIdentifiers {
                    if let productData = snapshotDict[productId] as? [String: AnyObject] {
                        if let price = productData["price"] as? Double,
                           let title = productData["title"] as? String,
                           let description = productData["description"] as? String {
                            let productDataModel = ProductDataModel(title: title, description: description, price: price)
                            productsData[productId] = productDataModel
                        }
                    }
                }

                completion(productsData)
                return
            }

            completion(nil)
        })
    }

    func getIAPProductsIdentifiers(_ completion: @escaping ([String]?) -> Void) {
        iapProductRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshotDict = snapshot.value as? [String: String] {
                var productsIdentifiers = [String]()

                for product in snapshotDict {
                    productsIdentifiers.append(product.1)
                }

                completion(productsIdentifiers)
                return
            }

            completion(nil)
        })
    }

    func getIAPSubscription(_ completion: @escaping (IAPSubscription?) -> Void) {
        if profileIAPRef == nil {
            completion(nil);
            return
        }

        let subscriptionRef = IAPSubscription.Subscription.ref
        let profileIapSubscriptionRef = FirebaseManager.sharedInstance.getReference(profileIAPRef!, childNames: subscriptionRef)

        profileIapSubscriptionRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let subscription = IAPSubscription(snapshot: snapshot)
            if subscription.isAValidSubscription() {
                completion(subscription)
                return
            }

            completion(nil)
        })
    }

    func setIAPTransactionError(_ transactionError: IAPTransactionError) {
        if profileIAPRef == nil {
            return
        }
        if !transactionError.isAValidTransactionError() {
            return
        }
        guard let transactionErrorValue = transactionError.getTransactionErrorValue() else {
            return
        }

        let transactionErrorRef = IAPTransactionError.TransactionError.ref
        let profileIAPTransactionErrorRef = FirebaseManager.sharedInstance.getReference(profileIAPRef!, childNames: transactionErrorRef)

        FirebaseManager.sharedInstance.setValue(profileIAPTransactionErrorRef, value: transactionErrorValue as AnyObject)
    }

}
