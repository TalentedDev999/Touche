//
//  PaymentObserver.swift
//  Touche-ios
//
//  Created by Lucas Maris on 19/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import StoreKit

extension IAPManager: SKPaymentTransactionObserver {

    // MARK: - Helper Methods

    fileprivate func completeTransaction(_ transaction: SKPaymentTransaction) {
        print("Purchase Transaction ...")

        SKPaymentQueue.default().finishTransaction(transaction)
        validateReceipt()

        // Log Purchase Success
        let eventId = AnalyticsManager.FieldsToLog.PurchaseSuccess
        let target = transaction.payment.productIdentifier
        AnalyticsManager.sharedInstance.logEvent(eventId, withTarget: target)
    }

    fileprivate func restoreTransaction(_ transaction: SKPaymentTransaction) {
        print("Restore Transaction ...")

        SKPaymentQueue.default().finishTransaction(transaction)
        validateReceipt()
    }

    fileprivate func failedTransaction(_ transaction: SKPaymentTransaction) {
        print("Transaction Failed ...")

//        if transaction.transactionState != SKError.paymentCancelled.rawValue {
//            let transactionError = IAPTransactionError(transaction: transaction)
//            FirebaseIAPManager.sharedInstance.setIAPTransactionError(transactionError)
//
//            // Log Purchase Cancelled
//            let eventId = AnalyticsManager.FieldsToLog.PurchaseWasCancelled
//            AnalyticsManager.sharedInstance.logEvent(eventId)
//        }

        SKPaymentQueue.default().finishTransaction(transaction)

        transactionErrorMessage = transaction.error?.localizedDescription
        let transactionErrorEvent = EventNames.Upgrade.transactionError
        MessageBusManager.sharedInstance.postNotificationName(transactionErrorEvent)
    }

    // MARK: - Payment Delegate

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("In App Purchases Payment Queue updatedTransactions")

        var lastPurchased: SKPaymentTransaction?
        var lastRestored: SKPaymentTransaction?
        var lastFailed: SKPaymentTransaction?

        for transaction in transactions {

            switch transaction.transactionState {

            case .purchased:
                print("Purchased=\(transaction.transactionIdentifier)")
                lastPurchased = transaction

            case .restored:
                print("Restored=\(transaction.transactionIdentifier)")
                lastRestored = transaction

            case .failed:
                print("Failed=\(transaction.transactionIdentifier)")
                lastFailed = transaction

            case .deferred:
                break
            case .purchasing:
                break
            }
        }


        if let lP = lastPurchased {
            completeTransaction(lP)
        }

        if let lR = lastRestored {
            restoreTransaction(lR)
        }

        if let lF = lastFailed {
            failedTransaction(lF)
        }
    }

}
