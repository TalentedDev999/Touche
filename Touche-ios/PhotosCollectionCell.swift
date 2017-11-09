//
//  PhotosCollectionCell.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import MBProgressHUD

class PhotosCollectionCell: UICollectionViewCell {
    
    static let name = "photo cell"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lockButton: UIButton!
    
    var picUUID: String?
    var hud: MBProgressHUD?
    
    var showHourGlass = false
    var showLock = false

    override func awakeFromNib() {
        super.awakeFromNib()
        
        hud = MBProgressHUD(view: imageView)
        imageView.addSubview(hud!)
        hud?.mode = .annularDeterminate
        
        lockButton.isHidden = true
        imageView.alpha = 1

        self.contentView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
        imageView.layer.borderWidth = 0.0
        
        picUUID = nil

        hud?.hide(animated: false)
    }
    
    func showHud(_ progress: Float) {
        if hud?.mode != .annularDeterminate {
            hud?.mode = .annularDeterminate
        }
        
        hud?.progress = progress
        hud?.show(animated: false)
    }
    
    func removeHud() {
        hud?.hide(animated: true)
    }
    
    func showErrorHud() {
        removeHud()
        
        hud?.mode = .customView
        hud?.show(animated: true)
    }

    func borderPrimary() {
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = Utils.redColorTouche.cgColor
    }
}
