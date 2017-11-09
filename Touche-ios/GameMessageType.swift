//
//  GameMessageType.swift
//  Touche-ios
//
//  Created by Lucas Maris on 15/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit

extension GameVC : MessageTypeProtocol {
    
    func tapOnMessageType(_ item: String) {
        print(item)
        
        switch item {
            
        case MessageTypeDelegate.TypeNames.Cards:
            showCardType()
        
        case MessageTypeDelegate.TypeNames.Photos:
            showImageType()
            
        default:
            break;
        }
    }
    
    fileprivate func showCardType() {
        actionCollectionView.isUserInteractionEnabled = true
        imageCollectionView.isUserInteractionEnabled = false
        
        Utils.executeInMainThread { [unowned self] in
            UIView.animate(withDuration: Utils.animationDuration, animations: {
                self.imageCollectionView.alpha = 0
                self.actionCollectionView.alpha = 1
            })
        }
    }
    
    fileprivate func showImageType() {
        actionCollectionView.isUserInteractionEnabled = false
        imageCollectionView.isUserInteractionEnabled = true
        
        Utils.executeInMainThread { [unowned self] in
            UIView.animate(withDuration: Utils.animationDuration, animations: {
                self.imageCollectionView.alpha = 1
                self.actionCollectionView.alpha = 0
            })
        }
    }
    
 }
