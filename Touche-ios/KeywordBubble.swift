//
//  KeywordBubble.swift
//  Touche-ios
//
//  Created by Lucas Maris on 23/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import SpriteKit

class KeywordBubble: Bubble {

    var backgroundColor = UIColor.clear
    var lineWidth: CGFloat = 10
    var cornerRadius: CGFloat = 20
    
    // MARK: - Init Methods
    init(size: CGSize, backgroundColor: UIColor, lineWidth: CGFloat, cornerRadius: CGFloat, scaleOptions: ScaleOptions?) {
        
        var scaleOpt: ScaleOptions?
        
        if let options = scaleOptions {
            scaleOpt = ScaleOptions(factor: options.factor, animationLength: options.animationLength)
        }
        
        super.init(texture: nil, color: UIColor.clear, size: size, scaleOptions: scaleOpt, id: "id")
        
        self.backgroundColor = backgroundColor
        self.lineWidth = lineWidth
        self.cornerRadius = cornerRadius
        
        setUpPhysicsBody()
        setUpShape()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setUpShape() {
        let x = -(size.width / 2) + lineWidth/2
        let y = -(size.height / 2) + lineWidth/2
        let width = size.width - lineWidth
        let height = size.height - lineWidth
        
        let rect = CGRect(x: x, y: y, width: width, height: height)
        let mask = SKShapeNode(rect: rect, cornerRadius: cornerRadius)
        mask.fillColor = backgroundColor
        mask.lineWidth = lineWidth
        mask.strokeColor = SKColor.clear
        
        Utils.executeInMainThread { [weak self] in
            self?.addChild(mask)
        }
    }
    
    override func setUpPhysicsBody() {
        physicsBody = SKPhysicsBody(rectangleOf: initialSize)
        physicsBody?.restitution = 0.0
        physicsBody?.friction = 0.3
        physicsBody?.linearDamping = 0.5
        physicsBody?.allowsRotation = false
    }
    
}
