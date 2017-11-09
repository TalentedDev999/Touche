//
//  ImageCollectionViewCell.swift
//  Touche-ios
//
//  Created by Lucas Maris on 15/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    static let name = "image cell"

    @IBOutlet weak var imageView: UIImageView!
    
    override func draw(_ rect: CGRect) {
        imageView.clipsToBounds = true
    }
}
