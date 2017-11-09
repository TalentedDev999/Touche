//
//  PeopleBubble.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/16/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import SpriteKit
import AlamofireImage

class PeopleBubble: Bubble {
    
    let user: ToucheUser!
    
    var imageView: UIImageView!
    
    init(user: ToucheUser, width: CGFloat, scaleOptions: ScaleOptions?) {
        self.user = user

        let initialWidth = width
        let initialSize = CGSize(width: initialWidth, height: initialWidth)

        var scaleOpt: ScaleOptions?
        
        if let options = scaleOptions {
            scaleOpt = ScaleOptions(factor: options.factor, animationLength: options.animationLength)
        }
        
        imageView = UIImageView(image: UIImage(named: ToucheApp.Assets.defaultImageName)!.circle!)
        
        let texture = SKTexture(image: imageView.image!)
    
        super.init(texture: texture, color: UIColor.clear, size: initialSize, scaleOptions: scaleOpt, id: user.userID!)
        
        setUpPhysicsBody()
        
        self.name = user.userID
        
        self.isUserInteractionEnabled = false
        
        let edge = PeopleBubble.edgeForCircleOfRadius(initialSize.width / 2)
        
        Utils.executeInMainThread { [weak self] in
            self?.addChild(edge)
        }
        
        downloadImage()
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
    
    fileprivate func downloadImage() {
        if let imgURL = user.avatarImageURL {
            imageView.af_setImage(withURL: imgURL,
                            placeholderImage: UIImage(named: ToucheApp.Assets.defaultImageName)!.circle!,
                            completion: { response in
                                if let image: UIImage = response.result.value {
                                    self.updateImage(image)
                                }
                            })

        }
    }
    
    fileprivate func updateImage(_ image: UIImage) {
        Utils.executeInBackgroundThread { [weak self] in
            guard let newImage = image.circle,
                let markImage = UIImage(named: ToucheApp.Assets.bubbleMark)?.circle else {
                    return
            }
            
            var texture:SKTexture
            
            if let mergedImage = Utils.maskImage(newImage, withMask: markImage) {
                texture = SKTexture(image: mergedImage)
            } else {
                texture = SKTexture(image: newImage)
            }
            
            Utils.executeInMainThread({ 
                self?.texture = texture
            })
        }
    }

}
