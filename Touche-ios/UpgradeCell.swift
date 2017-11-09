//
//  UpgradeCell.swift
//  Touche-ios
//
//  Created by Lucas Maris on 19/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import StoreKit

import MBProgressHUD

class UpgradeCell: UITableViewCell {

    static let name = "upgrade cell"

    var product: SKProduct?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    @IBOutlet weak var frequencyLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
        priceButton.roundViewWith(8)

        frequencyLabel.text = "per month".translate()
    }

    // MARK: - Events

    @IBAction func tapOnPriceButton(_ sender: AnyObject) {
        guard let product = product else {
            return
        }
        let wasProductAlreadyPurchased = IAPManager.sharedInstance.purchasedProducts.contains(product.productIdentifier)
        if !wasProductAlreadyPurchased && IAPManager.canMakePayments() {
            // close the actual upgrade popuver
            PopupManager.sharedInstance.dismiss({
                IAPManager.sharedInstance.showSubscriptionInfo {
                    IAPManager.sharedInstance.buyProduct(product)
                    MessageBusManager.sharedInstance.postNotificationName(EventNames.Upgrade.buyButtonWasPressed)
                }
            })
        }

        // Log
        let eventId = AnalyticsManager.FieldsToLog.PurchaseAttempt
        AnalyticsManager.sharedInstance.logEvent(eventId, withTarget: product.localizedTitle)
    }

}
