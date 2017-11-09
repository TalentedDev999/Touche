//
//  ActionCell.swift
//  Touche-ios
//
//  Created by Lucas Maris on 5/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class ActionCell: UICollectionViewCell {
    
    static let name = "action cell"
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var iconLabel: UILabel!
    
    override func draw(_ rect: CGRect) {
        backView.layer.borderWidth = 0.5
        backView.layer.borderColor = UIColor.lightGray.cgColor
        backView.layer.cornerRadius = 8
    }
}
