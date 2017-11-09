//
//  ConversationCell.swift
//  Touche-ios
//
//  Created by Ben LeBlond on 31/8/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class ConversationCell: UITableViewCell {
    
    // MARK: - Properties
    
    static let name = "conversation cell"
    
    @IBOutlet weak var imageAvatar: UIImageView! {
        didSet {
            imageAvatar.circle()
        }
    }
    
    @IBOutlet weak var labelUsername: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelLastMessage: UILabel!
    
    private let defaultImage:UIImage? = UIImage(named: ToucheApp.Assets.defaultImageName)
    
    var username:String? {
        didSet {
            labelUsername.text = username
        }
    }
    
    var date:String? {
        didSet {
            labelDate.text = date
        }
    }
    
    var lastMessage:String? {
        didSet {
            labelLastMessage.text = lastMessage
        }
    }
    
    var avatarURL:NSURL? {
        didSet {
            if let avatarURL = avatarURL {
                UIImageView().af_setImageWithURL(avatarURL,
                                placeholderImage: defaultImage,
                                imageTransition: .CrossDissolve(0.2))
            }
        }
    }
    
    // MARK: - Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
