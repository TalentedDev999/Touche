//
//  StoreKit Extensions.swift
//  Touche-ios
//
//  Created by Lucas Maris on 19/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import StoreKit

extension SKProduct {

    func getLocalizedMonthlyPrice(_ numOfMonths:Double) -> String {

//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.locale = priceLocale
//        formatter.roundingMode = .down
        
        let monthlyPrice = price.doubleValue / numOfMonths
        
//        guard let localizedPrice = formatter.string(from: monthlyPrice) else {
//            return String(monthlyPrice)
//        }

        return "\(monthlyPrice)"
    }

    func getLocalizedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        
        guard let localizedPrice = formatter.string(from: price) else {
            return String(describing: price)
        }
        
        return localizedPrice
    }
    
    func getLocalizedPriceWithLocalizedCurrency() -> String? {
        if let currencySymbol = Utils.getCurrentCurrencySymbol() {
            return "\(currencySymbol) \(getLocalizedPrice())"
        }
        
        return nil
    }
    
}
