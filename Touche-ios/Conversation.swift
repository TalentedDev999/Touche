//
//  Conversation.swift
//  Touche-ios
//
//  Created by Lucas Maris on 31/8/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import Firebase

class Conversation {
    
    // MARK: - Properties

    struct Nodes {
        static let conversation = "conversation"
        
        static let id = "id"
        static let lastMessage = "last_message"
    }
    
    var userWhoIChattedWith:String?
    
    var id:String?
    var lastMessage:ConversationMessage?
    
    // MARK: - Init Methods
    
    init(){}
    
    init(data:[String:AnyObject]) {
        if let id = data[Nodes.id] as? String {
            self.id = id
        }
        
        if let lastMessageData = data[Nodes.lastMessage] as? [String:AnyObject] {
            self.lastMessage = ConversationMessage(data: lastMessageData)
        }
    }
    
    convenience init(userWhoIChattedWith:String, data:[String:AnyObject]) {
        self.init(data: data)
        self.userWhoIChattedWith = userWhoIChattedWith
    }

    convenience init(snapshot: DataSnapshot) {
        guard let data = snapshot.value as? [String:AnyObject] else { self.init(); return }
        self.init(userWhoIChattedWith: snapshot.key, data: data)
    }
    
    // MARK: - Helper Methods
    
    fileprivate func stringDate(_ conversationDate:Date, dateProximity:DateManager.DateProximity) -> String {
        let dateFormatter = DateManager.getFormatterByProximity(dateProximity)
        var dateString = dateFormatter.string(from: conversationDate)
        
        if dateProximity == DateManager.DateProximity.today ||
            dateProximity == DateManager.DateProximity.yesterday
        {
            let hoursWithMinutesFormatter = DateManager.getHoursWithMinutesFormatter()
            dateString += " - \(hoursWithMinutesFormatter.string(from: conversationDate)) Hs"
        }
        
        return dateString
    }
    
    // MARK: - Methods
    
    func isAValidConversation() -> Bool {
        return userWhoIChattedWith != nil && id != nil && lastMessage != nil
    }
    
    func getStringDate() -> String? {
        if let conversationDate = lastMessage?.date {
            let dateProximity = DateManager.getProximityOfDate(conversationDate)
            return stringDate(conversationDate, dateProximity: dateProximity)
        }
        
        return nil
    }
    
}
