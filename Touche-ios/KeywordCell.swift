//
//  KeywordCell.swift
//  Touche-ios
//
//  Created by Lucas Maris on 27/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class KeywordCell: UITableViewCell {

    static let name = "keywordCell"
    
    @IBOutlet weak var typeImage: UIImageView!
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var tagListScrollView: UIScrollView!
    @IBOutlet weak var tagListHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
