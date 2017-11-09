//
//  HistoryCellModel.swift
//  Touche-ios
//
//  Created by Lucas Maris on 12/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

class HistoryCellModel {
    
    // MARK: - Properties
    
    var actionId:String
    var action:String
    var reaction:String
    
    // MARK: Init Methods
    
    init(actionId:String, action:String, reaction:String?) {
        self.actionId = actionId
        self.action = action
        if let reaction = reaction {
            self.reaction = reaction
        } else {
            self.reaction = "❓"
        }
    }
}