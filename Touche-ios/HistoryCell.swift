//
//  HistoryCell.swift
//  Touche-ios
//
//  Created by Lucas Maris on 12/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class HistoryCell: UICollectionViewCell {
    
    static let name = "History Cell"
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var arrow: UILabel!
    
    @IBOutlet weak var actionIcon: UILabel!
    @IBOutlet weak var reactionIcon: UILabel!
    
    
    override func draw(_ rect: CGRect) {
        backView.layer.borderWidth = 0.5
        backView.layer.borderColor = UIColor.lightGray.cgColor
        backView.layer.cornerRadius = 8 //backView.frame.size.width / 2
    }
}
