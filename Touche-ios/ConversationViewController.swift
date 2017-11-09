//
//  ConversationViewController.swift
//  Touche-ios
//
//  Created by Lucas Maris on 28/06/2017.
//  Copyright © 2017 toucheapp. All rights reserved.
//

import UIKit
import NoChat
import TwilioChatClient

class ConversationViewController: MMChatViewController {
    
    var channelSID: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(closeIfChannelRemoved), name: NSNotification.Name(rawValue: "channelDeleted"), object: nil)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }


    func closeIfChannelRemoved(_ notification: Notification) {
        if let csid = notification.object as? String {
            if csid == channelSID {
                (self as UIViewController).navigationController?.popViewController(animated: false)
            }
        }
    }

}
