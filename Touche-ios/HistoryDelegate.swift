//
//  HistoryDelegate.swift
//  Touche-ios
//
//  Created by Lucas Maris on 12/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit

class HistoryDelegate : NSObject, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Properties
    
    var collectionModel:[HistoryCellModel] {
        didSet {
            collectionView.reloadData()
            if collectionModel.count > 0 {
                let index = IndexPath(item: collectionModel.count - 1, section: 0)
                collectionView.scrollToItem(at: index, at: .left, animated: true)
            }
        }
    }
    var collectionView:UICollectionView!
    
    // MARK: - Init Methods
    
    init(collectionView:UICollectionView) {
        self.collectionView = collectionView
        self.collectionModel = [HistoryCellModel]()
        
        super.init()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    // MARK: - Helper Methods
    
    fileprivate func showHistory(_ cell:HistoryCell, item:Int) {
        cell.actionIcon.text = collectionModel[item].action
        cell.reactionIcon.text = collectionModel[item].reaction
    }
    
    func updateHistoryBy(_ actionId:String, withReaction:String) {
        var auxIndex:Int?
        for (index, action) in collectionModel.enumerated() {
            if action.actionId == actionId {
                auxIndex = index
                break
            }
        }
        
        if let index = auxIndex {
            collectionModel[index].reaction = withReaction
            collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        }
    }
    
    // MARK: - Collection View Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellName = HistoryCell.name
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath)
        
        if let cell = cell as? HistoryCell {
            showHistory(cell, item: indexPath.item)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let width = 90
        let height = 48
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.5
    }
    
}
