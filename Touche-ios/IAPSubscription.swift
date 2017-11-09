//
//  IAPSubscription.swift
//  Touche-ios
//
//  Created by Lucas Maris on 19/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import SwiftyJSON
import Firebase
import SwiftDate

open class IAPSubscription {
    
    // MARK: - Properties
    
    struct Subscription {
        static let ref = "subscription"
        
        static let expirationDate = "expiration_date"
        static let productId = "product_id"
        static let purchaseDate = "puchase_date"
        static let transactionId = "transaction_id"
    }
    
    var expirationDate:String?
    var productId:String?
    var purchaseDate:String?
    var transactionId:String?
    
    // MARK: - Init Methods
    
    init(data:[String:AnyObject]) {
        print(data)
        if let expirationDate = data[Subscription.expirationDate] as? String {
            self.expirationDate = expirationDate
        }
        
        if let productId = data[Subscription.productId] as? String {
            self.productId = productId
        }
        
        if let purchaseDate = data[Subscription.purchaseDate] as? String {
            self.purchaseDate = purchaseDate
        }
        
        if let transactionId = data[Subscription.transactionId] as? String {
            self.transactionId = transactionId
        }
    }
    
    init(json:JSON) {
        if let productId = JsonManager.getStringValueFrom(json, forFirstKey: Subscription.productId) {
            self.productId = productId
        }
        
        if let expirationDate = JsonManager.getStringValueFrom(json, forFirstKey: Subscription.expirationDate) {
            self.expirationDate = expirationDate
        }
        
        if let transactionId = JsonManager.getStringValueFrom(json, forFirstKey: Subscription.transactionId) {
            self.transactionId = transactionId
        }
    }

    init(snapshot: DataSnapshot) {
        print(snapshot)
        
        guard let snapshotDict = snapshot.value as? [String:AnyObject] else { return }
        
        if let productId = snapshotDict[Subscription.productId] as? String {
            self.productId = productId
        }
        
        if let expirationDate = snapshotDict[Subscription.expirationDate] as? String {
            self.expirationDate = expirationDate
        }
        
        if let transactionId = snapshotDict[Subscription.transactionId] as? String {
            self.transactionId = transactionId
        }
    }
    
    // MARK: - Helper Methods
    
    func isAValidSubscription() -> Bool {
        if productId != nil && expirationDate != nil && transactionId != nil {
            if let expiration = Double(expirationDate!) {
                return Date(timeIntervalSince1970: (expiration / 1000)).isInFuture
            }
        }
        
        return false
    }
    
}
