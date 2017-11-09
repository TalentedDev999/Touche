//
//  FirebaseChatManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 30/8/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import Firebase
import SwiftyJSON
import SwiftMessages

class FirebaseChatManager {

    // MARK: - Properties

    static let sharedInstance = FirebaseChatManager()

    fileprivate let messagesLimited: UInt = 25

    fileprivate var conversationRef: DatabaseReference
    fileprivate var conversationDataRef: DatabaseReference
    fileprivate var unreadRef: DatabaseReference

    fileprivate var conversationUserRef: DatabaseReference?
    fileprivate var conversationDataMessagesRef: DatabaseReference?
    fileprivate var conversationDataTypingIndicatorRef: DatabaseReference?

    fileprivate var profileRef: DatabaseReference

    fileprivate var conversationUserChangeObserver: UInt?
    fileprivate var messagesObserver: UInt?
    fileprivate var profileObserver: UInt?

    fileprivate var lastMessageChanged: ConversationMessage?

    var userWhoIAmChattingWith: String?
    var currentNavigationController: UINavigationController?
    var inGridConversationList = false

    var conversations = [Conversation]() {
        didSet {
            let conversationsDidChangeEvent = EventNames.Chat.Conversations.didChange
            MessageBusManager.sharedInstance.postNotificationName(conversationsDidChangeEvent)
        }
    }

    var unreadMessages = [String: Int]() {
        didSet {
            let totalUnreadMessagesDidChangeEvent = EventNames.Chat.UnreadMessages.totalUnreadMessagesDidChange
            MessageBusManager.sharedInstance.postNotificationName(totalUnreadMessagesDidChangeEvent)
        }
    }

    // MARK: - Methods

    fileprivate init() {
        let profileNode = FirebasePeopleManager.Database.Nodes.profile

        conversationRef = FirebaseManager.sharedInstance.getDatabaseReference(Conversation.Nodes.conversation)
        conversationDataRef = FirebaseManager.sharedInstance.getDatabaseReference(ConversationMessage.Nodes.conversationData)

        unreadRef = FirebaseManager.sharedInstance.getDatabaseReference(UnreadMessages.Nodes.unread)
        profileRef = FirebaseManager.sharedInstance.getDatabaseReference(profileNode)

        setupUserRef()
    }

    func setupUserRef() {
        if let toucheUUID = UserManager.sharedInstance.toucheUUID {
            conversationUserRef = FirebaseManager.sharedInstance.getReference(conversationRef, childNames: toucheUUID)
            conversationUserRef?.keepSynced(true)
        }
    }

    /*
     * Iterate over 'conversations' looking for a conversation with the user who is 'toUserUUID'
     * Return the id of the conversation with the user who is 'toUserUUID'
     * Return nil if no conversation with 'toUserUUID' was founded
    */
    fileprivate func getConversationIdWithUser(_ toUserUUID: String, fromConversations conversations: [Conversation]) -> String? {
        for conversation in conversations {
            if let userWhoIChattedWith = conversation.userWhoIChattedWith {
                if userWhoIChattedWith.caseInsensitiveCompare(toUserUUID) == ComparisonResult.orderedSame {
                    return conversation.id
                }
            }
        }

        return nil
    }

    /*
     * Look for a conversation in local conversations with the user who is 'toUserUUID'
     * Return the id of the conversation with the user who is 'toUserUUID'
     * Return nil if no conversation with 'toUserUUID' was founded
     */
    fileprivate func getConversationIdWithUser(_ toUserUUID: String) -> String? {
        return getConversationIdWithUser(toUserUUID, fromConversations: self.conversations)
    }

    /*
     * Retrieve all user converations from Firebase and iterate over them looking for a conversation with user who is 'uuid'
     * Return the id of the conversation with the user who is 'uuid'
     * Return nil if no conversation with the user who is 'uuid' was founded
    */
    fileprivate func getConversationIdAsyncWithUser(_ toUserUUID: String, withCompletion completion: @escaping (String?) -> Void) {
        getConversations { (conversations) in
            if let conversations = conversations {
                let conversationId = self.getConversationIdWithUser(toUserUUID, fromConversations: conversations)
                completion(conversationId)
                return
            }

            completion(nil)
        }
    }

    fileprivate func getConversationIdFromFirebaseWithUser(_ toUserUUID: String, withCompletion completion: @escaping (String?) -> Void) {
        guard let fromUUID = UserManager.sharedInstance.toucheUUID else {
            completion(nil);
            return
        }

        let idNode = Conversation.Nodes.id
        let conversationIdRef = FirebaseManager.sharedInstance.getReference(conversationRef, childNames: fromUUID, toUserUUID, idNode)

        conversationIdRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                if let conversationId = snapshot.value as? String {
                    completion(conversationId)
                    return
                }
            }

            completion(nil)
        })
    }

    /*
     * If no previous conversation between currentUser and remoteUser was founded
     * Create the conversation in Firebase
     */
    fileprivate func createNewConversationFor(_ fromUserUUID: String, toUserUUID: String) -> String {
        let newConversationDataRef = conversationDataRef.childByAutoId()

        let fromUserUUID = fromUserUUID.uppercased()
        let toUserUUID = toUserUUID.uppercased()
        let conversationIdChild = Conversation.Nodes.id
        let conversationIdValue = newConversationDataRef.key

        let localConversationRef = FirebaseManager.sharedInstance.getReference(conversationRef, childNames: fromUserUUID, toUserUUID, conversationIdChild)
        let remoteConversationRef = FirebaseManager.sharedInstance.getReference(conversationRef, childNames: toUserUUID, fromUserUUID, conversationIdChild)

        FirebaseManager.sharedInstance.setValue(localConversationRef, value: conversationIdValue as AnyObject)
        FirebaseManager.sharedInstance.setValue(remoteConversationRef, value: conversationIdValue as AnyObject)

        return conversationIdValue
    }

    fileprivate func updateConversationLastMessage(_ fromUserUUID: String, toUserUUID: String, lastMessageValue: AnyObject) {
        let fromUserUUID = fromUserUUID.uppercased()
        let toUserUUID = toUserUUID.uppercased()
        let lastMessageChild = Conversation.Nodes.lastMessage

        let conversationFromRef = FirebaseManager.sharedInstance.getReference(conversationRef, childNames: fromUserUUID, toUserUUID, lastMessageChild)
        let conversationToRef = FirebaseManager.sharedInstance.getReference(conversationRef, childNames: toUserUUID, fromUserUUID, lastMessageChild)

        FirebaseManager.sharedInstance.setValue(conversationFromRef, value: lastMessageValue)
        FirebaseManager.sharedInstance.setValue(conversationToRef, value: lastMessageValue)
    }

    /*
     * Try to return 'conversationId' from Firebase
     * Return new 'conversationId' if a previous conversation is not found in Firebase
     */
    fileprivate func getConversationIdWithUser(_ toUserUUID: String, withCompletion completion: @escaping (String?) -> Void) {
        getConversationIdFromFirebaseWithUser(toUserUUID) { (conversationId) in
            if let conversationId = conversationId {
                // 'conversationId' was found in Firebase
                completion(conversationId)
                return
            }

            // 'converationId' was not found in Firebase so then create new one
            if let fromUserUUID = UserManager.sharedInstance.toucheUUID {
                let conversationId = self.createNewConversationFor(fromUserUUID, toUserUUID: toUserUUID)
                completion(conversationId)
                return
            }

            completion(nil)
        }
    }

    /*
     * Fill 'conversations' from snapshot
    */
    fileprivate func getConversationsFrom(_ snapshot: DataSnapshot) -> [Conversation]? {
        guard let snapshotDict = snapshot.value as? [String: AnyObject] else {
            return nil
        }

        var conversations = [Conversation]()

        for (key, value) in snapshotDict {
            // Key = userWhoIChattedWith - Value = conversationData
            if let conversationData = value as? [String: AnyObject] {
                let conversation = Conversation(userWhoIChattedWith: key, data: conversationData)
                if conversation.isAValidConversation() {
                    conversations.append(conversation)
                }
            }
        }

        return conversations.isEmpty ? nil : conversations
    }

    fileprivate func conversationsDidChange(_ conversation: Conversation) {
        for (index, auxConversation) in conversations.enumerated() {
            if auxConversation.id == conversation.id {
                conversations.remove(at: index)
                conversations.insert(conversation, at: 0)
                return
            }
        }

        // New conversation
        conversations.insert(conversation, at: 0)
    }

    fileprivate func sendInAppNotification(_ conversation: Conversation) {
        print("NEW MESSAGE NOTIFICATION")

        if let fromUUID = UserManager.sharedInstance.toucheUUID,
           let lastMessage = conversation.lastMessage {
            if inGridConversationList {
                return
            }
            if !lastMessage.isAValidMessage() {
                return
            }
            if lastMessage.senderId! == fromUUID {
                return
            }
            if lastMessage.senderId! == userWhoIAmChattingWith {
                return
            }

//            let senderUUID = lastMessage.senderId!
//            let tapHandler = { [unowned self] (view: BaseView) in
//                if let nc = self.currentNavigationController {
//                    self.showConversationVCWithUser(senderUUID, nc: nc)
//                }
//            }

//            if lastMessage.type == ConversationMessage.MessageType.text {
//                let body = lastMessage.message!
//                let title = "💬"
//                NotificationsManager.sharedInstance.showInAppNotificationFrom(title, senderUUID: senderUUID, body: body, tapHandler: tapHandler)
//                return
//            }
//
//            if lastMessage.type == ConversationMessage.MessageType.photo {
//                let title = "📷"
//                NotificationsManager.sharedInstance.showInAppNotificationFrom(title, senderUUID: senderUUID, body: "", tapHandler: tapHandler)
//            }
        }
    }

    // MARK: - Conversation Methods

    /*
     * Try to retrieve all conversations of current user from Firebase
     */
    func getConversations(_ completion: @escaping ([Conversation]?) -> Void) {
        conversationUserRef?.observeSingleEvent(of: .value, with: { (snapshot) in
            if let conversations = self.getConversationsFrom(snapshot) {
                self.lastMessageChanged = conversations.last?.lastMessage
                completion(conversations)
                return
            }

            completion(nil)
        })
    }

    func startObserveUserConversations() {
        guard let conversationUserRef = conversationUserRef else {
            return
        }

        let lastConversationQuery = conversationUserRef.queryLimited(toLast: 1)

        lastConversationQuery.observe(.childAdded, with: { (snapshot) in
            let conversation = Conversation(snapshot: snapshot)
            if conversation.isAValidConversation() {
                self.conversationsDidChange(conversation)
                self.sendInAppNotification(conversation)
            }
        })

        conversationUserRef.observe(.childChanged, with: { (snapshot) in
            let conversation = Conversation(snapshot: snapshot)
            if conversation.isAValidConversation() {
                print("Conversation change \(snapshot)")
                self.conversationsDidChange(conversation)
                self.sendInAppNotification(conversation)
            }
        })

        conversationUserRef.observe(.childRemoved, with: { (snapshot) in
            print("Conversation removed \(snapshot)")
            let conv = Conversation(snapshot: snapshot)
            if let index = self.conversations.index(where: { $0.id == conv.id }) {
                self.conversations.remove(at: index)
            }
        })
    }

    // MARK: - Unread Messages

    func getUnreadMessages(_ completion: @escaping ([String: Int]) -> Void) {
        guard let fromUserUUID = UserManager.sharedInstance.toucheUUID else {
            return
        }
        let unreadMessagesForUser = FirebaseManager.sharedInstance.getReference(unreadRef, childNames: fromUserUUID)

        unreadMessagesForUser.observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            guard let unreadNode = snapshot.value as? [String: AnyObject] else {
                return
            }

            var unreadMessages = [String: Int]()

            for eachNode in unreadNode {
                if let unreadMessagesNode = eachNode.1 as? [String: Int] {
                    if let unreadMessagesCount = unreadMessagesNode[UnreadMessages.Nodes.unreadMessages] {
                        unreadMessages[eachNode.0] = unreadMessagesCount
                    }
                }
            }

            completion(unreadMessages)
        })
    }

    func getUnreadMessagesFor(_ toUserUUID: String, completion: @escaping (Int) -> Void) {
        guard let fromUserUUID = UserManager.sharedInstance.toucheUUID else {
            return
        }
        let unreadMessagesNodes = UnreadMessages.Nodes.unreadMessages
        let unreadMessagesRef = FirebaseManager.sharedInstance.getReference(unreadRef, childNames: fromUserUUID, toUserUUID, unreadMessagesNodes)

        unreadMessagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let unreadMessages = snapshot.value as? Int {
                completion(unreadMessages)
                return
            }

            completion(0)
        })
    }

    func getTotalUnreadMessagesFor(_ userUUID: String, completion: @escaping (Int) -> Void) {
        let unreadMessagesForUser = FirebaseManager.sharedInstance.getReference(unreadRef, childNames: userUUID)

        unreadMessagesForUser.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let unreadNode = snapshot.value as? [String: AnyObject] else {
                return
            }

            var total = 0

            for eachNode in unreadNode {
                if let unreadMessagesNode = eachNode.1 as? [String: Int] {
                    if let unreadMessagesCount = unreadMessagesNode[UnreadMessages.Nodes.unreadMessages] {
                        total += unreadMessagesCount
                    }
                }
            }

            completion(total)
        })
    }

    func startObserveUnreadMessages() {
        guard let fromUserUUID = UserManager.sharedInstance.toucheUUID else {
            return
        }
        let unreadMessagesForUser = FirebaseManager.sharedInstance.getReference(unreadRef, childNames: fromUserUUID)
        let queryLasUnreadMessage = unreadMessagesForUser.queryLimited(toLast: 1)

        queryLasUnreadMessage.observe(.childAdded, with: { (snapshot) in
            guard let unreadNode = snapshot.value as? [String: Int] else {
                return
            }
            guard let unreadMessages = unreadNode[UnreadMessages.Nodes.unreadMessages] else {
                return
            }
            self.unreadMessages[snapshot.key] = unreadMessages

            let unreadMessagesDidChangeEvent = EventNames.Chat.UnreadMessages.unreadMessagesDidChange
            let object: [String: Any] = ["uuid": fromUserUUID, "key": snapshot.key, "value": unreadMessages]
            MessageBusManager.sharedInstance.postNotificationName(unreadMessagesDidChangeEvent, object: object as AnyObject)
        })

        unreadMessagesForUser.observe(.childChanged, with: { (snapshot) in
            guard let unreadNode = snapshot.value as? [String: Int] else {
                return
            }
            guard let unreadMessages = unreadNode[UnreadMessages.Nodes.unreadMessages] else {
                return
            }
            self.unreadMessages[snapshot.key] = unreadMessages

            let unreadMessagesDidChangeEvent = EventNames.Chat.UnreadMessages.unreadMessagesDidChange
            let object: [String: Any] = ["uuid": fromUserUUID, "key": snapshot.key, "value": unreadMessages]
            MessageBusManager.sharedInstance.postNotificationName(unreadMessagesDidChangeEvent, object: object as AnyObject)
        })
    }

    func resetUnreadMessagesForConversationWith(_ fromUserUUID: String, toUserUUID: String, completion: @escaping (Bool) -> Void) {
        let unreadMessagesRef = FirebaseManager.sharedInstance.getReference(unreadRef, childNames: toUserUUID, fromUserUUID)

        unreadMessagesRef.runTransactionBlock({ (unread) -> TransactionResult in
            if var unreadNode = unread.value as? [String: Any] {
                if var unreadMessages = unreadNode[UnreadMessages.Nodes.unreadMessages] as? Int {
                    unreadNode[UnreadMessages.Nodes.unreadMessages] = 0
                }
                unread.value = unreadNode
            } else {
                unread.value = [UnreadMessages.Nodes.unreadMessages: 0] // set to 0 if it doesn't exist
            }

            return TransactionResult.success(withValue: unread)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(false)
                return
            }

            if committed {
                completion(true)
                return
            }
        }
    }

    func incrementUnreadMessagesForConversationWith(_ toUserUUID: String, completion: @escaping (Bool) -> Void) {
        guard let fromUserUUID = UserManager.sharedInstance.toucheUUID else {
            return
        }
        let unreadMessagesRef = FirebaseManager.sharedInstance.getReference(unreadRef, childNames: toUserUUID, fromUserUUID)

        unreadMessagesRef.runTransactionBlock({ (unread) -> TransactionResult in
            if var unreadNode = unread.value as? [String: Any] {
                if var unreadMessages = unreadNode[UnreadMessages.Nodes.unreadMessages] as? Int {
                    unreadMessages += 1
                    unreadNode[UnreadMessages.Nodes.unreadMessages] = unreadMessages
                }
                unread.value = unreadNode
            } else {
                unread.value = [UnreadMessages.Nodes.unreadMessages: 1] // set to 1 if it doesn't exist
            }

            return TransactionResult.success(withValue: unread)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(false)
                return
            }

            if committed {
                completion(true)
                return
            }
        }
    }

    func getUnreadMessagesForConversationWith(_ toUserUUID: String, completion: @escaping (Int?) -> Void) {
        guard let fromUserUUID = UserManager.sharedInstance.toucheUUID else {
            completion(nil);
            return
        }

        let unreadMessages = UnreadMessages.Nodes.unreadMessages
        let unreadMessagesRef = FirebaseManager.sharedInstance.getReference(unreadRef, childNames: fromUserUUID, toUserUUID, unreadMessages)

        unreadMessagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let unreadMessages = snapshot.value as? Int {
                completion(unreadMessages)
                return
            }

            completion(nil)
        })
    }

    func clearUnreadMessagesForConversationWith(_ toUserUUID: String) {
        guard let fromUserUUID = UserManager.sharedInstance.toucheUUID else {
            return
        }

        let unreadMessages = UnreadMessages.Nodes.unreadMessages
        let unreadMessagesRef = FirebaseManager.sharedInstance.getReference(unreadRef, childNames: fromUserUUID, toUserUUID, unreadMessages)

        unreadMessagesRef.setValue(0)
    }

    // MARK: - ConversationData Methods

    fileprivate func buildConversationMessagesFrom(_ snapshot: DataSnapshot) -> [ConversationMessage]? {
        guard let snapshotDict = snapshot.value as? [String: AnyObject] else {
            return nil
        }

        var messages = [ConversationMessage]()

        for (key, value) in snapshotDict {
            // Key = firebase id - value = messageData
            if let messageData = value as? [String: AnyObject] {
                let message = ConversationMessage(firebaseId: key, data: messageData)
                if message.isAValidMessage() {
                    messages.append(message)
                }
            }
        }

        return messages.isEmpty ? nil : messages
    }

    func retrieveMessagesFor(_ conversationId: String, completion: @escaping ([ConversationMessage]?) -> Void) {
        let messagesRef = ConversationMessage.Nodes.Messages.messages
        let conversationDataMessagesRef = FirebaseManager.sharedInstance.getReference(conversationDataRef, childNames: conversationId, messagesRef)
        conversationDataMessagesRef.keepSynced(true)

        conversationDataMessagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let messages = self.buildConversationMessagesFrom(snapshot)
            completion(messages)
        })
    }

    func deleteConversationFor(_ toUserUUID: String, completion: @escaping () -> Void) {

        getConversationIdFromFirebaseWithUser(toUserUUID) { (conversationId) in
            if let conversationId = conversationId {
                guard let fromUUID = UserManager.sharedInstance.toucheUUID else {
                    completion();
                    return
                }
                // conversation portion
                let conversationIdRef1 = FirebaseManager.sharedInstance.getReference(self.conversationRef, childNames: fromUUID, toUserUUID)
                let conversationIdRef2 = FirebaseManager.sharedInstance.getReference(self.conversationRef, childNames: toUserUUID, fromUUID)
                conversationIdRef1.removeValue()
                conversationIdRef2.removeValue()

                // data portion
                let messagesRef = ConversationMessage.Nodes.Messages.messages
                let conversationDataMessagesRef = FirebaseManager.sharedInstance.getReference(self.conversationDataRef, childNames: conversationId, messagesRef)
                conversationDataMessagesRef.removeValue()

                // unread portion
                self.resetUnreadMessagesForConversationWith(fromUUID, toUserUUID: toUserUUID, completion: { (result) in
                    print("reset unread")
                })
                self.resetUnreadMessagesForConversationWith(toUserUUID, toUserUUID: fromUUID, completion: { (result) in
                    print("reset unread")
                })

                completion();
            }
        }
    }

    func newTextMessageIn(_ conversationId: String, fromUserUUID: String, toUserUUID: String, messageId: String, message: String) {
        let messagesChild = ConversationMessage.Nodes.Messages.messages
        let conversationDataMessagesRef = FirebaseManager.sharedInstance.getReference(conversationDataRef, childNames: conversationId, messagesChild)
        let newMessageRef = conversationDataMessagesRef.childByAutoId()
        let newMessageValue: [String: Any] = [
                ConversationMessage.Nodes.Messages.id: messageId,
                ConversationMessage.Nodes.Messages.senderId: fromUserUUID,
                ConversationMessage.Nodes.Messages.type: ConversationMessage.MessageType.text,
                ConversationMessage.Nodes.Messages.message: message,
                ConversationMessage.Nodes.Messages.date: ServerValue.timestamp()
        ]

        FirebaseManager.sharedInstance.setValue(newMessageRef, value: newMessageValue as AnyObject)

        updateConversationLastMessage(fromUserUUID, toUserUUID: toUserUUID, lastMessageValue: newMessageValue as NSDictionary)

        // Consume
        let productId = FirebaseBankManager.ProductIds.ChatMessage
        FirebaseBankManager.sharedInstance.consume(productId)

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.typing)

        // Completion for send notification after update the unread tree
        incrementUnreadMessagesForConversationWith(toUserUUID) { (result) in
            if result {
                // Send in app notification if the user is online. Send push notification if the user is offline
                let notificationText = "💬 \(message)"
                NotificationsManager.sharedInstance.sendPushNotificationIfUserOffline(toUserUUID, text: notificationText)
            }
        }
    }

    func newPhotoMessageIn(_ conversationId: String, fromUserUUID: String, toUserUUID: String, messageId: String, imageURL: String) {
        let messagesChild = ConversationMessage.Nodes.Messages.messages
        let conversationDataMessagesRef = FirebaseManager.sharedInstance.getReference(conversationDataRef, childNames: conversationId, messagesChild)
        let newMessageRef = conversationDataMessagesRef.childByAutoId()
        let newMessageValue: [String: Any] = [
                ConversationMessage.Nodes.Messages.id: messageId,
                ConversationMessage.Nodes.Messages.senderId: fromUserUUID,
                ConversationMessage.Nodes.Messages.type: ConversationMessage.MessageType.photo,
                ConversationMessage.Nodes.Messages.message: imageURL,
                ConversationMessage.Nodes.Messages.date: ServerValue.timestamp()
        ]

        FirebaseManager.sharedInstance.setValue(newMessageRef, value: newMessageValue as AnyObject)

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.pictoBoxSnap)

        // Consume
        let productId = FirebaseBankManager.ProductIds.ChatMessage
        FirebaseBankManager.sharedInstance.consume(productId)

        updateConversationLastMessage(fromUserUUID, toUserUUID: toUserUUID, lastMessageValue: newMessageValue as AnyObject)

        // Completion for send notification after update the unread tree
        incrementUnreadMessagesForConversationWith(toUserUUID) { (result) in
            if result {
                // Send in app notification if the user is online. Send push notification if the user is offline
                let notificationText = "📷"
                NotificationsManager.sharedInstance.sendPushNotificationIfUserOffline(toUserUUID, text: notificationText)
            }
        }
    }

    func setIsTyping(_ conversationId: String, fromUserUUID: String, typing: Bool) {
        let typingIndicatorRef = ConversationMessage.Nodes.TypingIndicator.typingIndicator
        let conversationTypingIndicatorRef = FirebaseManager.sharedInstance.getReference(conversationDataRef, childNames: conversationId, typingIndicatorRef, fromUserUUID)
        FirebaseManager.sharedInstance.setValue(conversationTypingIndicatorRef, value: "\(typing)" as AnyObject)
    }

    func startObserveMessagesFor(_ conversationId: String, completion: @escaping (ConversationMessage?) -> Void) {
        let messagesRef = ConversationMessage.Nodes.Messages.messages
        conversationDataMessagesRef = FirebaseManager.sharedInstance.getReference(conversationDataRef, childNames: conversationId, messagesRef)

        let messagesQuery = conversationDataMessagesRef!.queryLimited(toLast: 1)
        messagesObserver = messagesQuery.observe(.childAdded, with: { (snapshot) in
            guard let messageData = snapshot.value as? [String: AnyObject] else {
                completion(nil);
                return
            }
            let message = ConversationMessage(firebaseId: snapshot.key, data: messageData)
            if message.isAValidMessage() {
                completion(message)
                return
            }

            completion(nil)
        })
    }

    func startObserveTypingFor(_ conversationId: String, userWhoIamChattingWith: String, completion: @escaping (Bool) -> Void) {
        let typingIndicatorChild = ConversationMessage.Nodes.TypingIndicator.typingIndicator
        conversationDataTypingIndicatorRef = FirebaseManager.sharedInstance.getReference(conversationDataRef, childNames: conversationId, typingIndicatorChild)

        messagesObserver = conversationDataTypingIndicatorRef?.observe(.childChanged, with: { (snapshot) in
            guard let isTyping = snapshot.value as? Bool else {
                completion(false);
                return
            }

            if snapshot.key.caseInsensitiveCompare(userWhoIamChattingWith) == ComparisonResult.orderedSame {
                completion(isTyping)
                return
            }

            completion(false)
        })
    }

    func stopObserveMessages() {
        if let messagesObserver = messagesObserver {
            conversationDataMessagesRef?.removeObserver(withHandle: messagesObserver)
        }
    }

    func stopObserveTypingIndicator() {
        conversationDataTypingIndicatorRef?.removeAllObservers()
    }

    // MARK: - Users Who I Chatted With Methods

    /*
     * Get the ids of the users who I chatted for retrieve the profiles from Algolia
     * To show the avatars in the conversation list
     */
    fileprivate func getIdOfUsersIn(_ conversations: [Conversation]) -> [String] {
        var ids = [String]()
        for conversation in conversations {
            if let userId = conversation.userWhoIChattedWith {
                ids.append(userId)
            }
        }
        return ids
    }

    fileprivate func fillUsersWhoIChattedWith(_ usersData: [JSON]) {

    }

    fileprivate func fillUsersFrom(_ conversations: [Conversation]) {

    }

    // MARK : - Profile

    func observeProfile(_ userUUID: String) {
        profileObserver = profileRef.child(userUUID).observe(.childChanged, with: { (snapshot) in
            if snapshot.exists() {
                guard let value = snapshot.value as? String else {
                    return
                }

                let profileDidChangedEvent = EventNames.Chat.Profile.profileDidChange
                let object = ["uuid": userUUID, "key": snapshot.key, "value": value]
                MessageBusManager.sharedInstance.postNotificationName(profileDidChangedEvent, object: object as AnyObject)
            }
        })
    }

    // MARK: - Navigation Methods

    func showConversationVCWithUser(_ toUserUUID: String, nc: UINavigationController?, withBottomTopAnimation: Bool = false) {
//        getConversationIdWithUser(toUserUUID) { (conversationId) in
//            let chatConversationVC = ChatConversationVC()
//            let dataSource = ToucheMessageDataSource(count: 0, pageSize: 500)
//
//            chatConversationVC.conversationId = conversationId
//            chatConversationVC.userWhoIamChattingWithUUID = toUserUUID
//            chatConversationVC.dataSource = dataSource
//
//            // Consume
//            let productId = FirebaseBankManager.ProductIds.StartConversation
//            FirebaseBankManager.sharedInstance.consume(productId)
//
//            // Log Start Conversation
//            AnalyticsManager.sharedInstance.logEvent(productId, withTarget: toUserUUID)
//
//            if withBottomTopAnimation {
//                chatConversationVC.popChatConversationWithUpDownAnimation = true
//
//                let transition = CATransition()
//                transition.duration = Utils.animationDuration
//                transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
//                transition.type = kCATransitionPush
//                transition.subtype = kCATransitionFromTop
//                nc?.view.layer.add(transition, forKey: kCATransition)
//                nc?.pushViewController(chatConversationVC, animated: false)
//            } else {
//                nc?.showViewController(chatConversationVC, sender: nil)
//            }
//
//        }
    }

}
