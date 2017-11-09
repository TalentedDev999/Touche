//
//  GameImage.swift
//  Touche-ios
//
//  Created by Lucas Maris on 15/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

extension GameVC : ImageCollectionViewProtocol {
    
    func tapOnImage(_ image: UIImage) {
        print("tap on image")
    }
    
    func tapOnAddImage() {
        showImagePicker()
    }
    
    // MARK: - Image Picker
    
    fileprivate func showImagePicker() {
//        let imagePickerController = ImagePickerController()
//        imagePickerController.delegate = self
//        Configuration.collapseCollectionViewWhileShot = false
//        
//        
//        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    


}
