//
//  Bubble.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/25/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import SpriteKit

struct ScaleOptions {
    var factor: CGFloat
    var animationLength: TimeInterval
}

enum Zoom: CGFloat{
    case `in` = 1
    case out = -1
}

struct ScreenPositions {
    let top: CGFloat
    let bottom: CGFloat
    let right: CGFloat
    let left: CGFloat
}

class Bubble: SKSpriteNode {
    
    let screenPositions: ScreenPositions
    
    let initialSize: CGSize!
    
    let scaleOptions: ScaleOptions?
    var scaled = false

    var id: String!

    init(texture: SKTexture?, color: UIColor, size: CGSize, scaleOptions: ScaleOptions?, id: String) {
        self.initialSize = size
        
        self.scaleOptions = scaleOptions
        
        let top = Utils.screenHeight + size.height
        let bottom = -size.height
        let right = Utils.screenWidth + size.width
        let left = -size.width
        self.screenPositions = ScreenPositions(top: top, bottom: bottom, right: right, left: left)
        
        super.init(texture: texture, color: color, size: size)
        
        self.zPosition = 1

        self.id = id
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Methods
    
    func scale(_ zoomDirection: Zoom) {
        var factor: CGFloat = 0
        
        if let scaleFactor = scaleOptions?.factor {
            if scaleFactor > 1 {
                factor = scaleFactor / 2
            }
        }
        
        let widthToResize = initialSize.width * factor * zoomDirection.rawValue
        let heightToResize = initialSize.height * factor * zoomDirection.rawValue
        
        let zoom = SKAction.resize(byWidth: widthToResize, height: heightToResize, duration: scaleOptions?.animationLength ?? 0)
        run(zoom)
        
        if zoomDirection == .in {
            scaled = true
        }
        else {
            scaled = false
        }
    }

    func setUpPhysicsBody() {
    }
    
}
