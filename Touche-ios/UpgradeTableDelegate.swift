//
//  UpgradeTableDelegate.swift
//  Touche-ios
//
//  Created by Lucas Maris on 19/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import StoreKit

extension UpgradeVC : UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Helper Methods
    
    fileprivate func configureUpgradeCell(_ cell:UpgradeCell, row:Int) {
        cell.product = upgradeModel[row]
    }
    
    fileprivate func showProductTitle(_ cell:UpgradeCell, row:Int) {
        //cell.titleLabel.text = upgradeModel[row].localizedTitle
        let productId = upgradeModel[row].productIdentifier
        if let productDataModel = productData[productId] {
            cell.titleLabel.text = productDataModel.title
        }
    }
    
    fileprivate func showProductDescription(_ cell:UpgradeCell, row:Int) {
        //cell.descriptionLabel.text = upgradeModel[row].localizedDescription
        let productId = upgradeModel[row].productIdentifier
        
        if let productDataModel = productData[productId] {
            
            cell.descriptionLabel.text = productDataModel.description
            
            for (pid, model) in productData {
                if model.price == 1 && productDataModel.price != 1 {
                    let monthToMonthPrice = upgradeModel.filter { $0.productIdentifier == pid }.first!.price.doubleValue
                    let monthlyPrice = upgradeModel[row].price.doubleValue / productDataModel.price
                    let savings = monthToMonthPrice - monthlyPrice
                    let percentSavings = 100 * (savings / monthToMonthPrice)
                    
                    let formatter = NumberFormatter()
                    formatter.roundingMode = .down
                    
                    var frequency:String
                    switch productDataModel.price {
                    case 6:
                        frequency = "semiyearly".translate()
                    case 3:
                        frequency = "quarterly".translate()
                    default:
                        frequency = "yearly".translate()
                    }
                    
//                    if let percentOff = formatter.string(from: percentSavings) {
//                        cell.descriptionLabel.text = "\(upgradeModel[row].getLocalizedPrice()) \(frequency) (\(percentOff)% off)"
//                    }
                    
                    break
                }
            }
        }
    }
    
    fileprivate func showProductPrice(_ cell:UpgradeCell, row:Int) {
        if IAPManager.canMakePayments() {
            let productId = upgradeModel[row].productIdentifier
            if let productDataModel = productData[productId] {
                cell.priceLabel.text = upgradeModel[row].getLocalizedMonthlyPrice(productDataModel.price)
            }
            
            return
        }
        
        cell.priceLabel.text = ""
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return upgradeModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UpgradeCell.name, for: indexPath)
        
        if let upgradeCell = cell as? UpgradeCell {
            let row = indexPath.row
            configureUpgradeCell(upgradeCell, row: row)
            showProductTitle(upgradeCell, row: row)
            showProductDescription(upgradeCell, row: row)
            showProductPrice(upgradeCell, row: row)
        }
        
        return cell
    }
    
}
