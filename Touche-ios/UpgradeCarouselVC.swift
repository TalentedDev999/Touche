//
//  UpgradeCarouselVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 21/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class UpgradeCarouselVC: UIViewController {
    
    // MARK: - Properties

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var textLabel:String?
    var image:UIImage?
    
    // MARK: - Init Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let textLabel = textLabel {
            label.text = textLabel
        }
        
        if let image = image {
            imageView.image = image
        }
    }
    
}
