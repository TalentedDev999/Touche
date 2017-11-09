//
//  ProductDataModel.swift
//  Touche-ios
//
//  Created by Lucas Maris on 10/2/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

class ProductDataModel {

    var title: String
    var description: String
    var price: Double

    init(title:String, description:String, price:Double) {
        self.title = title
        self.description = description
        self.price = price
    }

}
