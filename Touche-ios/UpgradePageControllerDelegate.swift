//
//  UpgradePageControllerDelegate.swift
//  Touche-ios
//
//  Created by Lucas Maris on 20/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

protocol UpgradePageControllerDelegate : class {
    
    func upgradePageControllerDidUpdatePageCount(_ count:Int)
    func upgradePageControllerDidUpdatePageIndex(_ index:Int)
    
}
