//
//  ImageCollectionViewDelegate.swift
//  Touche-ios
//
//  Created by Lucas Maris on 15/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class ImageCollectionViewDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Properties
    
    var collectionView:UICollectionView
    
    var imageModel:[UIImage] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    fileprivate var delegate:ImageCollectionViewProtocol
    
    fileprivate let iconColor = UIColor.white
    fileprivate let iconSize = CGSize(width: 60, height: 60)
    
    // MARK: Init Methods
    
    init(collectionView:UICollectionView, delegate:ImageCollectionViewProtocol) {
        self.collectionView = collectionView
        self.imageModel = [UIImage]()
        self.delegate = delegate

        super.init()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    // MARK: - Helper Methods
    fileprivate func showImage(_ cell: ImageCollectionViewCell, item: Int) {
        if item == 0 {
            //cell.imageView.image = UIImage.fontAwesomeIconWithName(.PlusSquare, textColor: iconColor, size: iconSize)
            cell.backgroundColor = UIColor.green
        } else {
            cell.imageView.image = imageModel[item - 1]
        }
    }
    
    
    // MARK: - Collection View Delegates
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageModel.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellName = ImageCollectionViewCell.name
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath)
        
        if let imageCell = cell as? ImageCollectionViewCell {
            showImage(imageCell, item: indexPath.item)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            delegate.tapOnAddImage()
            return
        }
        
        delegate.tapOnImage(UIImage())
    }
        
    // Use for size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let size = Utils.screenWidth / 3
        return CGSize(width: size, height: size)
    }
    
    // Use for interspacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layoutcollectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView!,layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, 0, 1, 0)
    }

}
