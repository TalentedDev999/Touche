//
//  TapOnBubble.swift
//  Touche-ios
//
//  Created by Lucas Maris on 18/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import SpriteKit

protocol BubbleDelegate {
    func tapOn(_ bubble: Bubble?)
    func didAction(_ action: Action)
}
