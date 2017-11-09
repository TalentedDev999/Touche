//
//  Action.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/29/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

import Firebase


class ActionModel {
    
    struct Action {
        static let name = "name"
        static let icon = "icon"
        static let price = "price"
        
        static let reaction = "reaction"
        static let reactionReceived = "reactionReceived"
        
        static let senderUUID = "senderUUID"
        static let date = "actionDate"
        static let draggingIndicator = "draggingIndicator"
        static let draggingDirection = "draggingDirection"
        
        static let reactionType = "reactionType"
    }
    
    fileprivate let invalidChar = "-1"
    
    // Action To Send
    var id:String
    var name:String
    var icon:String
    var price:String
    var reactionType:String
    
    // Action Sent
    var senderUUID:String
    var date:String
    
    // Action Received (Reaction)
    var directionOfReaction:String

    // MARK: Init Methods

    init(snapshot: DataSnapshot) {
        id = snapshot.key
        name = invalidChar
        icon = invalidChar
        price = invalidChar
        reactionType = ReactionModel.TypeName.defaultName
        
        senderUUID = invalidChar
        date = invalidChar
        
        directionOfReaction = ReactionModel.Direction.Empty
        
        guard let snapshotDict = snapshot.value as? [String:AnyObject] else {
            return
        }
        
        if let name = snapshotDict[Action.name] as? String {
            self.name = name
        }
        
        if let icon = snapshotDict[Action.icon] as? String {
            self.icon = icon
        }
        
        if let price = snapshotDict[Action.price] as? String {
            self.price = price
        }
        
        if let reactionType = snapshotDict[Action.reactionType] as? String {
            self.reactionType = reactionType
        }
        
        if let senderUUID = snapshotDict[Action.senderUUID] as? String {
            self.senderUUID = senderUUID
        }
        
        if let reactionReceived = snapshotDict[Action.reaction]?[ReactionModel.Reaction.Direction] as? String {
            self.directionOfReaction = reactionReceived
        }
    }
    
    // MARK: - Helper Methods
    
    func isAValidAction() -> Bool {
        return name != invalidChar &&
            icon != invalidChar &&
            price != invalidChar &&
            senderUUID != invalidChar
    }
    
    func isAValidActionToSend() -> Bool {
        return name != invalidChar && icon != invalidChar
    }
    
}
