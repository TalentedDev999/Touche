//
//  ConversationMessage.swift
//  Touche-ios
//
//  Created by Lucas Maris on 21/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import Firebase

class ConversationMessage {

    // MARK: - Properties
    
    struct Nodes {
        static let conversationData = "conversationData"
        
        struct Messages {
            static let messages = "messages"
            
            static let id = "id"
            static let senderId = "senderId"
            static let message = "message"
            static let date = "date"
            static let type = "type"
        }
        
        struct TypingIndicator {
            static let typingIndicator = "typingIndicator"
            static let isTyping = "isTyping"
        }
    }
    
    struct MessageType {
        static let text = "text"
        static let photo = "photo"
        static let location = "location"
    }
    
    static func isAnIncomingMessage(_ conversationMessage:ConversationMessage) -> Bool {
        guard let senderId = conversationMessage.senderId else { return false }
        guard let toucheUUID = UserManager.sharedInstance.toucheUUID else { return false }
        
        return senderId != toucheUUID
    }
    
    var id:String?
    var firebaseId:String?
    var senderId:String?
    var message:String?
    var date:Date?
    var type:String?
    
    // MARK: - Init Methods
    
    init() {}
    
    init(senderId:String, message:String, date:Date, type:String) {
        self.id = UUID().uuidString
        self.senderId = senderId
        self.message = message
        self.date = date
        self.type = type
    }
    
    init(data:[String:AnyObject]) {
        
        if let id = data[Nodes.Messages.id] as? String {
            self.id = id
        }
        
        if let senderId = data[Nodes.Messages.senderId] as? String {
            self.senderId = senderId
        }
        
        if let message = data[Nodes.Messages.message] as? String {
            self.message = message
        }
        
        if let msSince1970 = data[Nodes.Messages.date] as? Double {
            self.date = Date(timeIntervalSince1970: msSince1970 / 1000) // timeIntervalSince1970 must be in seconds
        }
        
        if let type = data[Nodes.Messages.type] as? String {
            self.type = type
        }
    }
    
    convenience init(firebaseId:String, data:[String:AnyObject]) {
        self.init(data: data)
        self.firebaseId = firebaseId
    }

    convenience init(snapshot: DataSnapshot) {
        guard let data = snapshot.value as? [String:AnyObject] else { self.init(); return }
        self.init(firebaseId: snapshot.key, data: data)
    }
    
    // MARK: - Helper Methods
    
    func isAValidMessage() -> Bool {
        return id != nil && senderId != nil && message != nil && date != nil && type != nil
    }
    
    func isATextMessage() -> Bool {
        return type == MessageType.text
    }
    
    func isAPhotoMessage() -> Bool {
        return type == MessageType.photo
    }
    
    func isALocationMessage() -> Bool {
        return type == MessageType.location
    }
    
}
