//
//  ProductRequestDelegate.swift
//  Touche-ios
//
//  Created by Lucas Maris on 19/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import StoreKit

extension IAPManager : SKProductsRequestDelegate {
 
    // MARK: - SKProductsRequestDelegate
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        productsRequestCompletionHandler?(response.products)
        clearRequestAndHandler()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products. \(error.localizedDescription)")
        clearRequestAndHandler()
    }
    
}
