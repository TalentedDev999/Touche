//
//  FirebaseConversationListDelegate.swift
//  Touche-ios
//
//  Created by Ben LeBlond on 31/8/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit

extension FirebaseConversationListVC : UITableViewDataSource, UITableViewDelegate {

    // MARK: - Helper Methods
    
    private func showAvatar(cell:ConversationCell, conversation:Conversation) {
        guard let userId = conversation.userWhoIChattedWith else {
            return
        }
        
        PeopleManager.sharedInstance.forEach(PeopleManager.Collections.Chat) { (user) in
            if user.userID == userId {
                cell.avatarURL = user.avatarImageURL
            }
        }
    }
    
    private func showName(cell:ConversationCell, conversation:Conversation) {
        cell.username = conversation.userWhoIChattedWith
    }
    
    private func showDate(cell:ConversationCell, conversation:Conversation) {
        cell.date = conversation.getStringDate()
    }
    
    private func showLastMessage(cell:ConversationCell, conversation:Conversation) {
        cell.lastMessage = conversation.lastMessage
    }
    
    // MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ConversationCell.name, forIndexPath: indexPath)
        
        if let conversationCell = cell as? ConversationCell {
            let conversation = conversations[indexPath.row]
            showAvatar(conversationCell, conversation: conversation)
            showName(conversationCell, conversation: conversation)
            showDate(conversationCell, conversation: conversation)
            showLastMessage(conversationCell, conversation: conversation)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let conversation = conversations[indexPath.row]
        if let userId = conversation.userWhoIChattedWith {
            FirebaseChatManager.sharedInstance.showConversationVCWithUser(userId, nc: navigationController)
        }
    }

}