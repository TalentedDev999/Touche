//
//  IAPManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 19/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import StoreKit
import Foundation

typealias ProductsRequestCompletionHandler = ([SKProduct]?) -> ()

class IAPManager: NSObject {

    // MARK: - Properties

    static let sharedInstance = IAPManager()

    var currentSubscription: IAPSubscription? {
        didSet {
            if currentSubscription!.isAValidSubscription() {
                fillPurchasedProducts(currentSubscription!)
            }

            deliverSubscriptionChangeEvent()
        }
    }

    var isAlreadyShowing = false

    // The Products Identifiers are filled up from Firebase
    var productsIdentifiers = [String]()
    var productsData = [String: ProductDataModel]() {
        didSet {
            retrieveProducts()
        }
    }

    var availableProducts = [SKProduct]()
    // Filled up from retrieveProducts
    var purchasedProducts = [String]()
    // Filled up from Firebase & validateReceipt

    var transactionErrorMessage: String?

    internal var productsRequest: SKProductsRequest?
    internal var productsRequestCompletionHandler: ProductsRequestCompletionHandler?

    // MARK: - Init Methods 

    override init() {
        super.init()

        SKPaymentQueue.default().add(self)
        print("Handling In App Purchases Queue")
    }

    func initialize() {
    }

    // MARK: - Helper Methods

    fileprivate func deliverSubscriptionChangeEvent() {
        let subscriptionDidChangeEvent = EventNames.Upgrade.subscriptionDidChange
        MessageBusManager.sharedInstance.postNotificationName(subscriptionDidChangeEvent)
    }

    fileprivate func fillPurchasedProducts(_ subscription: IAPSubscription) {
        if let productIdentifier = subscription.productId {
            if !purchasedProducts.contains(productIdentifier) {
                purchasedProducts.append(productIdentifier)
            }
        }
    }

    // Try to retrieve the products after that the products identifiers were obtained from Firebase
    fileprivate func retrieveProducts() {
        // Fill up the available products
        productsRequestCompletionHandler = { (products) in
            if let products = products {
                self.availableProducts = products
            }
        }

        productsRequest = SKProductsRequest(productIdentifiers: Set<String>(productsIdentifiers))
        productsRequest!.cancel()
        productsRequest!.delegate = self
        productsRequest!.start()
    }

    internal func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }

    fileprivate func deliverTransactionFinishNotification() {
        let transactionFinishEvent = EventNames.Upgrade.transactionFinished
        MessageBusManager.sharedInstance.postNotificationName(transactionFinishEvent)
    }

    // MARK: - Methods

    static func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

    func getEnv() -> String {
        var isSandbox = "PRODUCTION"

        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = NSData(contentsOf: receiptURL) else {
            isSandbox = "SANDBOX"
            return isSandbox
        }

        return isSandbox
    }

    func validateReceipt() {
        let isSandbox = getEnv()

        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            print("Can not get receiptURL");
            return
        }
        guard let receipt = try? Data(contentsOf: receiptURL) else {
            print("Can not get receipt from receiptURL \(receiptURL.absoluteString)");
            return
        }

        let receiptData = receipt.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))

        AWSLambdaManager.sharedInstance.validateReceipt(receiptData, env: isSandbox) { (result, exception, error) in
            if let error = error {
                let errorMsg = error.localizedDescription
                print("Error: \(errorMsg)")
                return
            }

            if let exception = exception {
                let exceptionMsg = exception.description
                print("Exception \(exceptionMsg)")
                return
            }
        }

    }


    func requestProducts(_ productsIdentifiers: Set<String>, completion: @escaping ProductsRequestCompletionHandler) {
        productsRequestCompletionHandler = completion

        productsRequest = SKProductsRequest(productIdentifiers: productsIdentifiers)
        productsRequest!.cancel()
        productsRequest!.delegate = self
        productsRequest!.start()
    }

    func getLocalizedProductTitleFrom(_ productId: String) -> String? {
        var localizedProductTitle: String?

        for product in availableProducts {
            if product.productIdentifier == productId {
                localizedProductTitle = product.localizedTitle
                break
            }
        }

        return localizedProductTitle
    }

    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()

        // Log
        let eventId = AnalyticsManager.FieldsToLog.PurchaseRestored
        AnalyticsManager.sharedInstance.logEvent(eventId)
    }

    func buyProduct(_ product: SKProduct) {
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }

    func showUpgradePopover(_ vc: UIViewController) {
        if isAlreadyShowing {
            return
        }
        PopupManager.sharedInstance.showActualUpgradePopover(vc)
    }

    func closeUpgradePopover() {
        isAlreadyShowing = false
    }

    func showSubscriptionInfo(_ completion: @escaping () -> Void) {

        let blabla = "Your subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Your iTunes account will automatically be charged at the same price for renewal within 24-hours prior to the end of the current period unless you change your subscription preferences in your App Store account settings. You can manage your subscriptions at any time through your App Store account settings after purchase. Any unused portion of a free trial period will be forfeited when making a purchase of an auto renewing subscription."

        let alert = UIAlertController(title: "Subscription Terms".translate(), message: blabla.translate(),
                preferredStyle: UIAlertControllerStyle.alert)

        alert.addAction(UIAlertAction(title: "Ok".translate(), style: .default, handler: { action in
            switch action.style {
            case .default:
                completion()

            case .cancel:
                print("cancel")

            case .destructive:
                print("destructive")
            }
        }))

        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(alert, animated: true, completion: nil)
        }
    }


}
