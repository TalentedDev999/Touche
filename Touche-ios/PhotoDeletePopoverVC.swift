//
//  PhotoDeletePopoverVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 5/10/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import PopupDialog

class PhotoDeletePopoverVC: UIViewController {

    var photoCollectionVC: PhotosCollectionVC?
    
    var popoverDialog:PopupDialog?
    @IBOutlet weak var imageView: UIImageView!
    var imageUUID: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.backgroundColor = UIColor.black

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.textboxQuestion)
    }

    // MARK: - Selectors
    
    @IBAction func tapOnCancel(_ sender: UIButton) {

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.boomerangFly)

        popoverDialog?.dismiss()
    }
    
    @IBAction func tapOnDelete(_ sender: UIButton) {
        let primaryPic = photoCollectionVC?.primaryPic
        
        if primaryPic == imageUUID {
            photoCollectionVC?.primaryPic = nil
        }

        FirebasePhotoManager.sharedInstance.removePic(imageUUID, primary: primaryPic)

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.pictoBoxErase)
        
        popoverDialog?.dismiss()
    }
    
}
