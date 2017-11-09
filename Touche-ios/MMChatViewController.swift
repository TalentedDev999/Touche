//
//  MMChatViewController.swift
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

import UIKit
import NoChat
import TwilioChatClient

class MMChatViewController: NOCChatViewController, UINavigationControllerDelegate, MessageManagerDelegate, MMChatInputTextPanelDelegate, MMTextMessageCellDelegate {

    var messageManager = MessageManager.manager
    var layoutQueue = DispatchQueue(label: "com.little2s.nochat-example.mm.layout", qos: DispatchQoS(qosClass: .default, relativePriority: 0))

    let chat: Chat
    var channel: TCHChannel!

    // MARK: Overrides

    override class func cellLayoutClass(forItemType type: String) -> Swift.AnyClass? {
        if type == "Text" {
            return MMTextMessageCellLayout.self
        } else if type == "Date" {
            return MMDateMessageCellLayout.self
        } else if type == "System" {
            return MMSystemMessageCellLayout.self
        } else {
            return nil
        }
    }

    override class func inputPanelClass() -> Swift.AnyClass? {
        return MMChatInputTextPanel.self
    }

    override func registerChatItemCells() {
        collectionView?.register(MMTextMessageCell.self, forCellWithReuseIdentifier: MMTextMessageCell.reuseIdentifier())
        collectionView?.register(MMDateMessageCell.self, forCellWithReuseIdentifier: MMDateMessageCell.reuseIdentifier())
        collectionView?.register(MMSystemMessageCell.self, forCellWithReuseIdentifier: MMSystemMessageCell.reuseIdentifier())
    }

    init(chat: Chat) {
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
        isInverted = false
        chatInputContainerViewDefaultHeight = 50
        messageManager.addDelegate(self)

//        TwilioChatManager.shared.startChannel(channelId: chat.chatId) { (success, channel) in
//            if let channel = channel {
//                self.channel = channel
//                channel.delegate = self
//            }
//        }

        //NotificationCenter.default.addObserver(self, selector: #selector(typingDidStart(notification:)), name: NSNotification.Name(rawValue: "TypingStartedOnChannel"), object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(typingDidStart(notification:)), name: NSNotification.Name(rawValue: "TypingEndedOnChannel"), object: nil)

    }

//    func typingDidStart(notification: Notification) {
//        if let channelSid = notification.userInfo?["channelId"] as? String {
//            if channelSid == chat.chatId {
//                (inputPanel as! MMChatInputTextPanel).typingIndicator.startAnimating()
//            }
//        }
//    }
//
//    func typingDidEnd(notification: Notification) {
//        if let channelSid = notification.userInfo?["channelId"] as? String {
//            if channelSid == chat.chatId {
//                (inputPanel as! MMChatInputTextPanel).typingIndicator.stopAnimating()
//            }
//        }
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        messageManager.removeDelegate(self)
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //backgroundView?.image = UIImage(named: "MMWallpaper")!

        backgroundView?.image = UIImage(named: ToucheApp.bg)

        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.isNavigationBarHidden = false

        navigationController?.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadMessages()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collectionView && scrollView.isTracking {
            inputPanel?.endInputting(true)
        }
    }

    // MARK: MMChatInputTextPanelDelegate

    func didInputTextPanelStartInputting(_ inputTextPanel: MMChatInputTextPanel) {
        //self.channel.typing()
        //self.channel.synchronize { (result) in
        //}
        if isScrolledAtBottom() == false {
            scrollToBottom(animated: true)
        }
    }

    func inputTextPanel(_ inputTextPanel: MMChatInputTextPanel, requestSendText text: String) {
        let msg = Message()
        msg.text = text

        self.sendMessage(msg)
    }

    // MARK: MMTextMessageCellDelegate

    func didTapLink(cell: MMTextMessageCell, linkInfo: [AnyHashable: Any]) {
        inputPanel?.endInputting(true)

        guard let command = linkInfo["command"] as? String else {
            return
        }
        let msg = Message()
        msg.text = command
        sendMessage(msg)
    }

    // MARK: MessageManagerDelegate

    func didReceiveMessages(messages: [Message], chatId: String) {
        if isViewLoaded == false {
            return
        }

        if chatId == chat.chatId {
            addMessages(messages, scrollToBottom: true, animated: true)
            // mark messages as read
            for message in messages {
                NotificationCenter.default.post(name: NSNotification.Name("messageRead"), object: message)
            }
        }
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if self === navigationController.topViewController {
            return
        }

        isInControllerTransition = true

        guard let tc = navigationController.topViewController?.transitionCoordinator else {
            return
        }
        tc.notifyWhenInteractionEnds { [weak self] (context) in
            guard let strongSelf = self else {
                return
            }
            if context.isCancelled {
                strongSelf.isInControllerTransition = false
            }
        }
    }

    // MARK: Private

    private func loadMessages() {
        layouts.removeAllObjects()

        messageManager.fetchMessages(withChatId: chat.chatId) { [weak self] (msgs) in
            if let strongSelf = self {
                strongSelf.addMessages(msgs, scrollToBottom: true, animated: false)
            }
        }
    }

    private func sendMessage(_ message: Message) {
        message.isOutgoing = true
        message.senderId = UserManager.sharedInstance.toucheUUID!
        message.deliveryStatus = .Read

        addMessages([message], scrollToBottom: true, animated: true)

        messageManager.sendMessage(message, toChat: chat)
    }

    private func addMessages(_ messages: [Message], scrollToBottom: Bool, animated: Bool) {
        layoutQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            let count = strongSelf.layouts.count
            let indexes = IndexSet(integersIn: count..<count + messages.count)

            var layouts = [NOCChatItemCellLayout]()

            for message in messages {
                let layout = strongSelf.createLayout(with: message)!
                layouts.append(layout)
            }

            DispatchQueue.main.async {
                strongSelf.insertLayouts(layouts, at: indexes, animated: animated)
                if scrollToBottom {
                    strongSelf.scrollToBottom(animated: animated)
                }
            }
        }
    }

//    func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, messageAdded message: TCHMessage!) {
//        let formattedMessage = Message()
//        formattedMessage.date = message.dateUpdatedAsDate
//        formattedMessage.text = message.body
//        formattedMessage.msgId = "\(message.index)"
//        formattedMessage.senderId = message.author
//        formattedMessage.isOutgoing = message.author == UserManager.sharedInstance.toucheUUID
//
//        print("setLastConsumedMessageIndex=\(message.index)")
//        channel.messages.setLastConsumedMessageIndex(message.index)
//
//        if !formattedMessage.isOutgoing {
//            addMessages([formattedMessage], scrollToBottom: true, animated: true)
//        }
//
//    }
//
//    func chatClient(_ client: TwilioChatClient!, typingStartedOn channel: TCHChannel!, member: TCHMember!) {
//        if member.userInfo.identity != UserManager.sharedInstance.toucheUUID {
//            (inputPanel as! MMChatInputTextPanel).typingIndicator.startAnimating()
//        }
//    }
//
//    func chatClient(_ client: TwilioChatClient!, typingEndedOn channel: TCHChannel!, member: TCHMember!) {
//        (inputPanel as! MMChatInputTextPanel).typingIndicator.stopAnimating()
//    }

}

