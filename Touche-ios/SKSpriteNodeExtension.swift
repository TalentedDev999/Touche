//
//  SKSpriteNodeExtension.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/16/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import SpriteKit

public extension SKSpriteNode {
    
    func aspectFillToSize(_ fillSize: CGSize) {
        
        if texture != nil {
            self.size = texture!.size()
            
            let verticalRatio = fillSize.height / self.texture!.size().height
            let horizontalRatio = fillSize.width /  self.texture!.size().width
            
            let scaleRatio = horizontalRatio > verticalRatio ? horizontalRatio : verticalRatio
            
            self.setScale(scaleRatio)
        }
    }
    
}
