//
//  TwilioChatManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 27/06/2017.
//  Copyright © 2017 toucheapp. All rights reserved.
//

import UIKit
import TwilioChatClient
import SwiftyJSON
import Tabby

class TwilioChatManager: NSObject, TwilioChatClientDelegate {

    static let shared = TwilioChatManager()

    private var isInitialized = false

    private var channels: [String: TCHChannel] = [:]
    private var conversations: [String: String] = [:]

    //private var unread: [String: Int] = [:]

    var twilioClient: TwilioChatClient!

    required override internal init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(messageRead), name: NSNotification.Name(rawValue: "messageRead"), object: nil)
    }

    func setUpTwilioClient() {
        guard UserManager.sharedInstance.twilioToken != nil else {
            return
        }
        self.initializeTwilio()
    }


    private func initializeTwilio() {
        if let twilioToken = UserManager.sharedInstance.twilioToken {

            let accessManager = TwilioAccessManager.init(token: twilioToken, delegate: self)

            let properties = TwilioChatClientProperties()
            properties.initialMessageCount = 1
            properties.synchronizationStrategy = .all

            UIApplication.shared.isNetworkActivityIndicatorVisible = true

            self.twilioClient = TwilioChatClient.init(token: accessManager?.currentToken, properties: properties, delegate: self)

        }
    }


    func chatClient(_ client: TwilioChatClient!, synchronizationStatusChanged status: TCHClientSynchronizationStatus) {
        switch status {
        case .completed:
            isInitialized = true
            MessageBusManager.sharedInstance.postNotificationName(EventNames.Login.twilioReady)
            break
        default:
            break
        }
    }

    func chatClient(_ client: TwilioChatClient!, channelAdded channel: TCHChannel!) {
        NotificationCenter.default.post(name: NSNotification.Name("channelAdded"), object: channel.sid)
    }

    func chatClient(_ client: TwilioChatClient!, channelDeleted channel: TCHChannel!) {
        NotificationCenter.default.post(name: NSNotification.Name("channelDeleted"), object: channel.sid)
    }

    func messageRead(_ notification: Notification) {
        if let message = notification.object as? Message {
            if let channel = self.channels[message.chatId] {
                channel.messages.setLastConsumedMessageIndex(NSNumber(value: message.msgIndex))

                if let lastConsumedIndex = channel.messages.lastConsumedMessageIndex {
                    print("unread=\(message.msgIndex - lastConsumedIndex.intValue)")
                }
            }
        }
    }

    func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, messageAdded message: TCHMessage!) {
        let formattedMessage = Message()
        formattedMessage.date = message.dateUpdatedAsDate
        formattedMessage.text = message.body
        formattedMessage.senderId = message.author
        formattedMessage.msgIndex = message.index.intValue
        formattedMessage.chatId = channel.sid
        formattedMessage.isOutgoing = message.author == UserManager.sharedInstance.toucheUUID

        if let lastConsumedIndex = channel.messages.lastConsumedMessageIndex {
            //print("lastConsumedIndex=\(lastConsumedIndex)")
            print("unread=\(message.index.intValue - lastConsumedIndex.intValue)")
        } else {
            print("unread=\(message.index.intValue)")
        }


        if formattedMessage.isOutgoing {
            print("sent--->\(message.body)")
        } else {
            NotificationCenter.default.post(name: NSNotification.Name("messageAdded"), object: formattedMessage)

            SoundManager.sharedInstance.playSound(SoundManager.Sounds.mainMenuLetter)
            print("received--->\(message.body)")

            // store

//            self.deriveUUIDFromChannel(channel) { uuid in
//
//            }

        }

    }

    func channelsList(completion: @escaping ([String]) -> Void) {
        twilioClient.channelsList().userChannels { (result: TCHResult?, paginator: TCHChannelPaginator?) in
            if let result = result, let paginator = paginator {
                if result.isSuccessful() {
                    let sids = paginator.items().map {
                        ($0 as TCHChannel).sid!
                    }
                    completion(sids)
                }
            }
        }
    }

    func sendMessage(_ message: String, toChannel channelId: String) {
        guard let channel = channels[channelId] else {
            print("Message NOT sent.")
            return
        }
        let twilioMessage = channel.messages.createMessage(withBody: message)
        channel.messages.send(twilioMessage) { (result) in
            if let result = result {
                if result.isSuccessful() {
                    print("Message sent.")

                    SoundManager.sharedInstance.playSound(SoundManager.Sounds.typing)
                    self.deriveUUIDFromChannel(channel) { uuid in
                        NotificationsManager.sharedInstance.sendNotification(uuid, title: "", text: message)
                    }

                } else {
                    print("Message NOT sent.")

                    // todo: show in app notification
                }
            }
        }
    }

    func initChat(withUuid: String, completion: @escaping (String) -> Void) {
        if let csid = conversations[withUuid] {
            completion(csid)
        } else {
            AWSLambdaManager.sharedInstance.initChat(withUuid) { result, exception, error in
                if result != nil {
                    let jsonResult = JSON(result!)
                    let channelSid = jsonResult["channelSid"].stringValue
                    self.conversations[withUuid] = channelSid
                    completion(channelSid)
                }
            }
        }
    }

    func startChannel(channelId: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
        if channels[channelId] == nil {
            twilioClient.channelsList().channel(withSidOrUniqueName: channelId) { (result, channel) in
                if let channel = channel {

                    self.channels[channelId] = channel
                    channel.join(completion: { (result) in
                        completion(true, channel)
                    })
                }
                completion(false, nil)
            }
        } else {
            completion(true, channels[channelId])
        }
    }

    func retrieveMessages(channelId: String, messagesCount: Int = 25, completion: @escaping ([Message]) -> Void) {
        guard let channel = channels[channelId] else {
            twilioClient.channelsList().channel(withSidOrUniqueName: channelId) { (result, channel) in
                self.channels[channelId] = channel
                self.retrieveMessages(channelId: channelId, completion: completion)
            }
            return
        }

        if let messages = channel.messages {
            messages.getLastWithCount(UInt(messagesCount), completion: { (result, messages) in
                var formattedMessages = [Message]()
                if let messages = messages {
                    for message in messages {
                        let formattedMessage = Message()
                        formattedMessage.date = message.dateUpdatedAsDate
                        formattedMessage.text = message.body
                        formattedMessage.senderId = message.author
                        formattedMessage.msgIndex = message.index.intValue
                        formattedMessage.isOutgoing = message.author == UserManager.sharedInstance.toucheUUID
                        formattedMessages.append(formattedMessage)
                    }
                }
                completion(formattedMessages)
            })
        }
    }

    func retrievePicture(channelId: String, completion: @escaping (UIImage?) -> Void) {
        guard let channel = channels[channelId] else {
            twilioClient.channelsList().channel(withSidOrUniqueName: channelId) { (result, channel) in
                self.channels[channelId] = channel
                self.retrievePicture(channelId: channelId, completion: completion)
            }
            return
        }

        self.deriveUUIDFromChannel(channel) { uuid in
            PhotoManager.sharedInstance.getAvatarImageFor(uuid, completion: { (image) in
                completion(image)
            })
        }
    }

    func deriveUUIDFromChannel(_ channel: TCHChannel, completion: @escaping (String) -> Void) {
        channel.members.members(completion: { (result, paginator) in
            for member in (paginator?.items())! {
                if member.userInfo.identity! != UserManager.sharedInstance.toucheUUID {
                    completion(member.userInfo.identity!)
                }
            }
        })
    }

}

extension TwilioChatManager: TwilioAccessManagerDelegate {
    func accessManagerTokenWillExpire(_ accessManager: TwilioAccessManager) {
        LoginManager.refreshTokens(UserManager.sharedInstance.toucheUUID!) { success in
            if success {
                accessManager.updateToken(UserManager.sharedInstance.twilioToken!)
            }
        }
    }

    func accessManager(_ accessManager: TwilioAccessManager!, error: Error!) {
        print("Access manager error: \(error.localizedDescription)")
    }
}
