//
//  StateManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 10/10/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

class StateManager {

    // MARK: - Properties

    static let sharedInstance = StateManager()

    fileprivate let freeCycles = 1

    // MARK: - Init Methods

    fileprivate init() {

    }

    // MARK: - Methods

    func shouldShowAds() -> Bool {
        if UserManager.sharedInstance.isPremium() {
            return false
        }

        // Free cycle at the begining
        if UserManager.sharedInstance.numberOfCycles < freeCycles {
            return false
        }

        return true
    }

    func shouldShowFacebookPopover(_ completion: @escaping (Bool) -> Void) {
        FirebasePeopleManager.sharedInstance.getNumberOfCycles { (numberOfCycles) in
            if numberOfCycles < self.freeCycles {
                completion(false)
                return
            }

            FirebasePeopleManager.sharedInstance.isPrimaryPicSetted { (result) in
                completion(!result)
            }
        }
    }

}
