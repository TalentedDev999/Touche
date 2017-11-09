//
//  GameModel.swift
//  Touche-ios
//
//  Created by Lucas Maris on 2/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class GameModel {

    // MARK: Properties
    
    var gameId:String
    var fromUUID:String
    var toUUID:String
    
    init(gameId:String, fromUUID:String, toUUID:String) {
        self.gameId = gameId
        self.fromUUID = fromUUID
        self.toUUID = toUUID
    }
    
    
}