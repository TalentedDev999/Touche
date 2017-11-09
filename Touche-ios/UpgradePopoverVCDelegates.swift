//
//  UpgradePopoverVCDelegates.swift
//  Touche-ios
//
//  Created by Lucas Maris on 26/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

extension UpgradePopoverVC : UpgradePageControllerDelegate {
    
    func upgradePageControllerDidUpdatePageCount(_ count: Int) {
        pageControl.numberOfPages = count
    }
    
    func upgradePageControllerDidUpdatePageIndex(_ index: Int) {
        pageControl.currentPage = index
    }
    
}
