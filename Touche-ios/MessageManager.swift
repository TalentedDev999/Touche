//
//  MessageManager.swift
//  NoChat-Swift-Example
//
//  Copyright (c) 2016-present, little2s.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

protocol MessageManagerDelegate: class {
    func didReceiveMessages(messages: [Message], chatId: String)
}

class MessageManager: NSObject {

    private var delegates: NSHashTable<AnyObject>

    private var messages: Dictionary<String, [Message]>

    override init() {
        delegates = NSHashTable<AnyObject>.weakObjects()
        messages = [:]
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(messageAdded), name: NSNotification.Name(rawValue: "messageAdded"), object: nil)

    }

    static let manager = MessageManager()

    func messageAdded(_ notification: Notification) {
        if let message = notification.object as? Message {
            for delegate in delegates.allObjects {
                if let d = delegate as? MessageManagerDelegate {
                    d.didReceiveMessages(messages: [message], chatId: message.chatId)
                }
            }
        }
    }

    func fetchMessages(withChatId chatId: String, handler: @escaping ([Message]) -> Void) {
        TwilioChatManager.shared.retrieveMessages(channelId: chatId, completion: { (messages) in
            //self.saveMessages(messages, chatId: chatId)
            handler(messages)
        })
    }

    func sendMessage(_ message: Message, toChat chat: Chat) {
        let chatId = chat.chatId
        //saveMessages([message], chatId: chatId)

        TwilioChatManager.shared.sendMessage(message.text, toChannel: chatId)
    }

    func addDelegate(_ delegate: MessageManagerDelegate) {
        delegates.add(delegate)
    }

    func removeDelegate(_ delegate: MessageManagerDelegate) {
        delegates.remove(delegate)
    }

//    func clientDidReceiveMessage(_ message: [AnyHashable : Any]) {
//        guard let senderId = message["from"] as? String,
//            let type = message["type"] as? String,
//            let text = message["text"] as? String,
//            let chatType = message["ctype"] as? String else {
//                return;
//        }
//
//        if type != "Text" || chatType != "bot" {
//            return;
//        }
//
//        let msg = Message()
//        msg.senderId = senderId
//        msg.msgType = type
//        msg.text = text
//        msg.isOutgoing = false
//
//        let chatId = chatType + "_" + senderId
//
//        //saveMessages([msg], chatId: chatId)
//
//        for delegate in delegates.allObjects {
//            if let d = delegate as? MessageManagerDelegate {
//                d.didReceiveMessages(messages: [msg], chatId: chatId)
//            }
//        }
//    }

//    private func saveMessages(_ messages: [Message], chatId: String) {
//        var msgs = self.messages[chatId] ?? []
//        msgs += messages
//        self.messages[chatId] = msgs
//    }

}
