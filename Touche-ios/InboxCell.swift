//
//  InboxCell.swift
//  Touche-ios
//
//  Created by Lucas Maris on 27/06/2017.
//  Copyright © 2017 toucheapp. All rights reserved.
//

import UIKit
import SwiftDate
import AlamofireImage
import SwiftyJSON
import Cupcake

class InboxCell: UITableViewCell {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!

    func setUp(updateDate: Date, avatar: String, message: String) {

        self.backgroundColor = UIColor.clear
        self.messageLabel.textColor = Color("#FFF")!
        self.messageDateLabel.textColor = Color("#D40265")!

        activityIndicator.stopAnimating()
        messageLabel.text = message
        let d_str = try! updateDate.colloquialSinceNow()
        messageDateLabel.text = d_str.colloquial

        //self.avatarImageView.image = UIImage(named: ToucheApp.Assets.defaultImageName)

        FirebasePeopleManager.sharedInstance.getProfile(avatar) { (profile) in
            if let profile = profile, let picUuid = profile.pic, let status = profile.status {
                if status == "online" {
                    self.avatarImageView.addSubview(ImageView.img("$001-circle").tint(UIColor.green))
                } else {
                    self.avatarImageView.addSubview(ImageView.img("$001-circle").tint(UIColor.darkGray))
                }

                let imgURL = PhotoManager.sharedInstance.getPhotoURLFromName(picUuid, userUuid: avatar, size: 80)

                self.avatarImageView.af_setImage(withURL: imgURL,
                        placeholderImage: UIImage(named: ToucheApp.Assets.defaultImageName)!.circle!,
                        filter: AspectScaledToFillSizeCircleFilter(size: CGSize(width: 80.0, height: 80.0)),
                        imageTransition: .flipFromRight(0.5), runImageTransitionIfCached: true)
            }

        }

    }

}
