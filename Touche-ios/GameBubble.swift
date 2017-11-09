//
//  GameBubble.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/1/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import SpriteKit

class GameBubble: Bubble {
    
    let gameModel:GameModel!
    
    fileprivate var imageView: UIImageView!
    
    // MARK: Init Methods
    
    init(gameModel: GameModel, width: CGFloat, scaleOptions: ScaleOptions?) {
        self.gameModel = gameModel
        
        let initialWidth = width
        let initialSize = CGSize(width: initialWidth, height: initialWidth)
        
        var scaleOpt: ScaleOptions?
        
        if let options = scaleOptions {
            scaleOpt = ScaleOptions(factor: options.factor, animationLength: options.animationLength)
        }
        
        imageView = UIImageView(image: UIImage(named: ToucheApp.Assets.defaultImageName)!.circle!)
        
        let texture = SKTexture(image: imageView.image!)
        
        super.init(texture: texture, color: UIColor.clear, size: initialSize, scaleOptions: scaleOpt, id: gameModel.gameId)
        
        setUpPhysicsBody()

        self.name = gameModel.toUUID
        
        self.isUserInteractionEnabled = false
        
        let edge = GameBubble.edgeForCircleOfRadius(initialSize.width / 2)
        
        addChild(edge)
        
        PhotoManager.sharedInstance.getAvatarImageFor(gameModel.toUUID) { (image) in
            if image != nil {
                self.updateImage(image!)
            }
        }
    }
    
    fileprivate static func edgeForCircleOfRadius(_ radius: CGFloat) -> SKShapeNode {
        let lineWidth: CGFloat = 2
        let circle = SKShapeNode(circleOfRadius: radius - lineWidth + 1)
        circle.strokeColor = UIColor.clear
        circle.lineWidth = lineWidth
        return circle
    }
    
    override func setUpPhysicsBody() {
        let radius = initialSize.width / 2
        
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.restitution = 0.0
        physicsBody?.friction = 0.3
        physicsBody?.linearDamping = 0.5
        physicsBody?.allowsRotation = false
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updateImage(_ image: UIImage) {
        Utils.Queue.background.async { [unowned self] in
            guard let newImage = image.circle else {
                return
            }
            
            let texture = SKTexture(image: newImage)
            
            Utils.executeInMainThread {
                self.texture = texture
            }
        }
    }
    
}
