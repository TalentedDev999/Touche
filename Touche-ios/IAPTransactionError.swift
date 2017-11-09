//
//  IAPTransactionError.swift
//  Touche-ios
//
//  Created by Lucas Maris on 21/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import StoreKit

class IAPTransactionError {

    // MARK: - Properties
    
    struct TransactionError {
        static let ref = "transactionError"
        
        static let transactionId = "transactionId"
        static let date = "date"
        static let error = "error"
        static let appUsername = "app_username"
        static let productId = "product_id"
    }
    
    var id:String?
    var date:Date?
    var errorMessage:String?
    
    var appUsername:String?
    var productId:String?
    
    // MARK: - Init Methods
    
    init(transaction:SKPaymentTransaction) {
        id = transaction.transactionIdentifier
        date = transaction.transactionDate
        errorMessage = transaction.error?.localizedDescription
        
        appUsername = transaction.payment.applicationUsername
        productId = transaction.payment.productIdentifier
    }
    
    // MARK: - Helper Methods
    
    func getTransactionErrorValue() -> [String:String]? {
        var transactionErrorValue = [String:String]()
        
        if let id = id {
            transactionErrorValue[TransactionError.transactionId] = id
        }
        
        if let date = date {
            let dateFormatter = DateManager.getDefaultFormatter()
            let strDate = dateFormatter.string(from: date)
            transactionErrorValue[TransactionError.date] = strDate
        }
        
        if let errorMessage = errorMessage {
            transactionErrorValue[TransactionError.error] = errorMessage
        }
        
        if let appUsername = appUsername {
            transactionErrorValue[TransactionError.appUsername] = appUsername
        }
        
        if let productId = productId {
            transactionErrorValue[TransactionError.productId] = productId
        }
        
        return transactionErrorValue.isEmpty ? nil : transactionErrorValue
    }
    
    func isAValidTransactionError() -> Bool {
        return id != nil || date != nil || errorMessage != nil || appUsername != nil || productId != nil
    }
    
}
