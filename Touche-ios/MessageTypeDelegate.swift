//
//  MessageTypeDelegate.swift
//  Touche-ios
//
//  Created by Lucas Maris on 15/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class MessageTypeDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Properties
    
    struct TypeNames {
        static let Cards = "cards"
        static let Photos = "photos"
    }
    
    fileprivate let iconColor = UIColor.white
    fileprivate let iconSize = CGSize(width: 40, height: 40)
    
    fileprivate var messageTypeModel:[String]
    
    
    var collectionView:UICollectionView
    var delegate:MessageTypeProtocol
    
    // MARK: Init Methods
    
    init(collectionView:UICollectionView, delegate:MessageTypeProtocol) {
        self.collectionView = collectionView
        messageTypeModel = [TypeNames.Cards, TypeNames.Photos]
        self.delegate = delegate
        
        super.init()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    // MARK: - Helper Methods
    
    fileprivate func showIcon(_ cell:MessageTypeCollectionViewCell, item:Int) {
        let icon = messageTypeModel[item]
        
        switch icon {
        
        case TypeNames.Cards:
            cell.backgroundColor = UIColor.blue
            //cell.imageView.image = UIImage.fontAwesomeIconWithName(.SquareO, textColor: iconColor, size: iconSize)
        
        case TypeNames.Photos:
            cell.backgroundColor = UIColor.blue
            //cell.imageView.image = UIImage.fontAwesomeIconWithName(.Camera, textColor: iconColor, size: iconSize)
        
        default:
            break
        }
    }
    
    fileprivate func tapOnMessageType(_ item:String) {
        delegate.tapOnMessageType(item)
    }
    
    // MARK: - Collection View Delegates
 
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messageTypeModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellName = MessageTypeCollectionViewCell.name
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath)
        
        if let messageTypeCell = cell as? MessageTypeCollectionViewCell {
            showIcon(messageTypeCell, item: indexPath.item)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = messageTypeModel[indexPath.item]
        tapOnMessageType(item)
    }
    
    // Use for size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let width = 44
        let height = 44
        return CGSize(width: width, height: height)
    }
    
    // Use for interspacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2
    }
    
}
