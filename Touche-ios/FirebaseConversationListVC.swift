//
//  FirebaseConversationListVC.swift
//  Touche-ios
//
//  Created by Ben LeBlond on 31/8/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class FirebaseConversationListVC: UIViewController {
    
    // MARK: - Properties
    
    var conversations = [Conversation]()
    
    @IBOutlet weak var table: UITableView! {
        didSet {
            table.dataSource = self
            table.delegate = self
        }
    }
    
    // MARK: - Initializers Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.navigationControllerSetup(navigationController)
        Utils.navigationItemSetup(navigationItem)
        Utils.setViewBackground(view)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        conversations = FirebaseChatManager.sharedInstance.conversations
        table.reloadData()
        
        let conversationsDidChangeEvent = EventNames.Chat.Conversations.metadataDidChange
        let conversationsDidChangeSelector = #selector(FirebaseConversationListVC.conversationsDidChange)
        MessageBusManager.sharedInstance.addObserver(self, selector: conversationsDidChangeSelector, name: conversationsDidChangeEvent)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        MessageBusManager.sharedInstance.removeObserver(self)
    }
    
    // MARK: - Methods
    
    
    // MARK: - Selectors
    
    func conversationsDidChange() {
        print("ConversationList - conversations did Change")
        let newConversations = FirebaseChatManager.sharedInstance.conversations
        let index = FirebaseChatManager.sharedInstance.conversationsChangeAtIndex
        let indexPath = NSIndexPath(forItem: index, inSection: 0)
        
        conversations = newConversations
        table.reloadData()
        //table.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
