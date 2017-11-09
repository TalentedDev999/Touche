//
//  InboxViewController.swift
//  Touche-ios
//
//  Created by Lucas Maris on 27/06/2017.
//  Copyright © 2017 toucheapp. All rights reserved.
//

import UIKit
import SwiftyJSON
import TwilioChatClient
import Cupcake
import NVActivityIndicatorView

class ChatChannel {

    var sid: String

    init(sid: String) {
        self.sid = sid
    }
}


class InboxViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var inboxTableView: UITableView!

    var channels: [String] = []
    var channelData: [String: Dictionary<String, Any>] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        Utils.setViewBackground(self.view)

        //self.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 100)

        self.inboxTableView.separatorColor = UIColor.darkGray

        navigationController?.isNavigationBarHidden = false

        NotificationCenter.default.addObserver(self, selector: #selector(loadChannels), name: NSNotification.Name(rawValue: "channelAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadChannels), name: NSNotification.Name(rawValue: "channelDeleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRow), name: NSNotification.Name(rawValue: "messageAdded"), object: nil)

        //loadChannels()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadChannels()

        self.inboxTableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections: Int = 0
        if self.channels.count > 0 {
            tableView.separatorStyle = .singleLine
            numOfSections = 1
            tableView.backgroundView = nil
        } else {
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text = "No data available".translate()
            noDataLabel.textColor = UIColor.white
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
        }
        return numOfSections
    }

    func refreshRow(_ notification: Notification) {
        if let message = notification.object as? Message {

            if let idx = channels.index(of: message.chatId) {
                self.fetchChannelData(channels[idx])
                //self.sortChannelData()
                //self.inboxTableView.reloadData()
                let indexPath = IndexPath(item: idx, section: 0)
                self.inboxTableView.reloadRows(at: [indexPath], with: .top)
            }

            //self.inboxTableView.reloadData()
        }

    }

    func loadChannels() {
        inboxTableView.isHidden = true

        NVActivityIndicatorPresenter.sharedInstance.startAnimating(ToucheApp.activityData)
        TwilioChatManager.shared.channelsList() { sids in

            NVActivityIndicatorPresenter.sharedInstance.stopAnimating()

            self.inboxTableView.isHidden = false
            self.channelData.removeAll(keepingCapacity: false)
            self.channels.removeAll(keepingCapacity: false)

            for channelID in sids {
                self.fetchChannelData(channelID)
            }

            //self.refreshData()
        }

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "inboxCell", for: indexPath) as? InboxCell {

            cell.imageView?.image = nil
            cell.avatarImageView.image = nil
            cell.messageLabel.str("")
            cell.messageLabel.str("")

            let csid = channels[indexPath.row]

            if let data = self.channelData[csid] {
                if let date = data["date"], let uuid = data["uuid"] {
                    if let body = data["body"] {
                        cell.setUp(updateDate: date as! Date, avatar: uuid as! String, message: body as! String)
                    } else {
                        cell.setUp(updateDate: date as! Date, avatar: uuid as! String, message: "")
                    }
                }
            }

            return cell
        }
        return UITableViewCell()
    }

    private func fetchChannelData(_ channelID: String) {

        TwilioChatManager.shared.startChannel(channelId: channelID, completion: { (result, channel) in
            if let channel = channel {

                if let members: TCHMembers = channel.members {
                    members.members(completion: { (paginator) in
                        if let result: TCHResult = paginator.0 {
                            if result.isSuccessful() {
                                let tmembers = (paginator.1! as! TCHMemberPaginator).items()
                                let uuids = (tmembers as [TCHMember]).map {
                                            ($0.userInfo as TCHUserInfo).identity
                                        }
                                        .filter {
                                            $0 != UserManager.sharedInstance.toucheUUID!
                                        }

                                if let uuid = uuids.first {
                                    self.channelData[channelID] = [
                                            "date": channel.dateUpdatedAsDate ?? Date(),
                                            "uuid": uuid
                                    ]

                                    TwilioChatManager.shared.retrieveMessages(channelId: channelID, messagesCount: 1, completion: { (messages) in
                                        if messages.count > 0 {
                                            self.channelData[channelID] = [
                                                    "uuid": uuid,
                                                    "date": messages.first!.date,
                                                    "count": messages.count,
                                                    "body": messages.first!.text
                                            ]
                                        }
                                        Utils.executeInMainThread {
                                            self.refreshData()
                                        }
                                    })
                                }

                            }
                        }
                    })
                }



            }
        })


    }

    private func refreshData() {
        print("refreshData...")

        self.sortChannelData()
        self.inboxTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }

    private func sortChannelData() {
        let sorted = self.channelData.sorted(by: { (a, b) in
            ((a.value)["date"] as! Date) > ((b.value)["date"] as! Date)
        }).map({ $0.key })
        self.channels = Array(sorted)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = Chat()
        chat.chatId = channels[indexPath.row]
        let conversationController = ConversationViewController(chat: chat)
        conversationController.channelSID = channels[indexPath.row]
        navigationController?.pushViewController(conversationController, animated: true)
    }

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }


}
