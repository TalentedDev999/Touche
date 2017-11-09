//
//  GameActions.swift
//  Touche-ios
//
//  Created by Lucas Maris on 5/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit

extension GameVC: UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Helper Methods
    
    fileprivate func showImage(_ actionCell:ActionCell, item:Int) {
        let action = actionsAvailable[item]
        actionCell.iconLabel.text = action.icon
    }
    
    fileprivate func sendActionToFirebase(_ item:Int) {
        if cardsModel.count < cardsLimit {
            let actionToSend = actionsAvailable[item]
            actionsAvailable.remove(at: item)
        }
    }
    
    // MARK: - CollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actionsAvailable.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellName = ActionCell.name
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath)
        
        if let actionCell = cell as? ActionCell {
            showImage(actionCell, item: indexPath.row)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        sendActionToFirebase(indexPath.row)
    }
    
    // Use for size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let width = 88
        let height = 112
        return CGSize(width: width, height: height)
    }
    
    // Use for interspacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.5
    }
    
}
