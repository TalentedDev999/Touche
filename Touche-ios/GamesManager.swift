//
//  GamesManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/30/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit

class GamesManager {
    
    static func showGame(_ gameModel:GameModel, nv:UINavigationController?, showActionBar:Bool = false) {
        print("screen take over")
        let peopleStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.people , bundle: nil)
        if let gameController = peopleStoryboard.instantiateViewController(withIdentifier: ToucheApp.ViewControllerNames.gameVC) as? GameVC {
            gameController.gameModel = gameModel
            gameController.showActionBar = showActionBar
            nv?.present(gameController, animated: true, completion: nil)
            
            //nv?.showViewController(gameController, sender: nil)
        }
    }
    
    fileprivate var gamesBadge:Int {
        didSet {
            MessageBusManager.sharedInstance.postNotificationName(EventNames.Games.newGames)
        }
    }

    // MARK: Singleton

    static let sharedInstance = GamesManager()
    
    fileprivate init() {
        gamesBadge = 0
    }
    
    func updateGamesBadge(_ value: Int) {
        gamesBadge = value
    }
    
    func increaseGamesBadge() {
        gamesBadge += 1
    }
    
    func decreaseGamesBadge() {
        gamesBadge -= 1
    }
    
    func getGamesBadge() -> Int {
        return gamesBadge
    }
}
