//
//  KeywordsScene.swift
//  Touche-ios
//
//  Created by Lucas Maris on 23/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import SpriteKit
import SwiftMessages

class KeywordScene: SKScene {
    
    var bubbleDelegate: BubbleDelegate?
    
    // Initial Scene setup
    fileprivate let throwDirections: [Directions]
    fileprivate let throwOverBubbles: Bool!
    fileprivate let throwSpeed: TimeInterval!
    
    fileprivate var bubbles = [Bubble]()
    
    fileprivate var gravityField: SKFieldNode!
    fileprivate var centerPoint: CGPoint!
    
    fileprivate var touchedBubble: Bubble?
    fileprivate var touchedBubbleId: String?
    fileprivate var velocity = CGPoint.zero
    
    fileprivate var lastTouch: CGPoint!
    
    var timer: Timer?

    fileprivate var actionsCompleted = [Action]()
    
    // MARK: - Methods
    
    init(size: CGSize, throwDirections: [Directions], throwOver: Bool, throwSpeed: TimeInterval) {
        self.throwDirections = throwDirections
        self.throwOverBubbles = throwOver
        self.throwSpeed = throwSpeed
        super.init(size: size)
        
        gravitySetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func gravitySetup() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        centerPoint = CGPoint(x: self.frame.midX, y: self.frame.midY)
        gravityField = SKFieldNode.radialGravityField()
        gravityField.position = centerPoint
        gravityField.falloff = 0
        gravityField.strength = 2.5
        gravityField.isEnabled = true
        gravityField.isUserInteractionEnabled = false
        
        Utils.executeInMainThread { [unowned self] in
            self.addChild(self.gravityField)
        }
    }
    
    func addBubble(_ bubble: Bubble) {
        Utils.executeInMainThread { [weak self] in
            self?.bubbles.append(bubble)
            
            self?.addChild(bubble)
        }
    }
    
    func removeBubble(_ bubble: Bubble) {
        if let index = bubbles.index(of: bubble) {
            bubbles.remove(at: index)
        }
        
        Utils.executeInMainThread {
            bubble.removeFromParent()
        }
    }
    
    func findBubbleById(_ id: String) -> Bubble? {
        for bubble in bubbles {
            if bubble.id == id {
                return bubble
            }
        }
        return nil
    }
    
    func removeBubbleById(_ id: String) {
        bubbles.forEach {
            (bubble) in
            
            if bubble.id == id {
                Utils.executeInMainThread({ [weak self] in
                    self?.removeBubble(bubble)
                    bubble.removeFromParent()
                })
            }
        }
    }
    
    func removeAllBubbles() {
        bubbles.forEach {
            (bubble) in
            Utils.executeInMainThread({ 
                bubble.removeFromParent()
            })
        }
        bubbles.removeAll()
    }
    
    func stopScene() {
        scene?.view?.isPaused = true
    }
    
    func startScene() {
        scene?.view?.isPaused = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchedBubble == nil {
            guard let touch = touches.first else {
                return
            }
            
            let location = touch.location(in: self)
            lastTouch = location
            
            if let touchedNode = atPoint(location) as? Bubble {
                touchedBubble = touchedNode
                touchedBubbleId = touchedBubble?.id
            } else if let touchedNode = atPoint(location).parent as? Bubble {
                touchedBubble = touchedNode
                touchedBubbleId = touchedBubble?.id
            }
            
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(KeywordScene.draggingStarted), userInfo: nil, repeats: false)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
    
        let location = touch.location(in: self)
        touchedBubble?.position = location
        velocity.x = lastTouch.x - location.x
        velocity.y = lastTouch.y - location.y
        self.lastTouch = location

        if let touchedNode = atPoint(location) as? Bubble {
            if touchedNode.id == touchedBubbleId {
                touchedBubble = touchedNode
                if touchedBubble == touchedNode {
                    touchedNode.position = location
                }
            }
        } else if let touchedNode = atPoint(location).parent as? Bubble {
            if touchedNode.id == touchedBubbleId {
                touchedBubble = touchedNode
                if touchedBubble == touchedNode {
                    touchedNode.position = location
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        timer?.invalidate()
        timer = nil

        let hasVelocity = abs(velocity.x) > 10.0 || abs(velocity.y) > 10.0
        
        if hasVelocity {
            detectAction()
        } else {
            velocity = CGPoint.zero
            draggingStoped()
            touchedBubble = nil
            touchedBubbleId = nil
        }
    }

    fileprivate func detectAction() {
        guard let touchedBubble = touchedBubble else {
            return
        }
        
        var direction: Directions?
        
        if abs(velocity.x) > abs(velocity.y) {
            // horizontal movement
            if velocity.x > 0 && throwDirections.contains(Directions.left) {
                direction = .left
            } else if throwDirections.contains(Directions.right) {
                direction = .right
            }
        } else {
            // vertical movement
            if velocity.y > 0 && throwDirections.contains(Directions.bottom) {
                direction = .bottom
            } else if throwDirections.contains(Directions.top) == true {
                direction = .top
            }
        }
        
        if let dir = direction {
            performAction(Action(direction: dir, initialPosition: touchedBubble.position, bubble: touchedBubble))
        } else {
            self.touchedBubble = nil
            self.velocity = CGPoint.zero
        }
    }
    
    func performAction(_ action: Action) {
        var move: SKAction!
        
        switch action.direction {
        case .top:
            move = SKAction.moveTo(y: action.bubble.screenPositions.top, duration: throwSpeed)
            
        case .bottom:
            move = SKAction.moveTo(y: action.bubble.screenPositions.bottom, duration: throwSpeed)
            
        case .right:
            move = SKAction.moveTo(x: action.bubble.screenPositions.right, duration: throwSpeed)
            
        case .left:
            move = SKAction.moveTo(x: action.bubble.screenPositions.left, duration: throwSpeed)
        }
        
        if throwOverBubbles == true {
            action.bubble.physicsBody = nil
            action.bubble.zPosition = 10
        }
        
        action.bubble.run(move!, completion: {
            () -> Void in
            self.bubbleDelegate?.didAction(action)
            self.touchedBubble = nil
            self.velocity = CGPoint.zero
        })
    }
    
    func undoLastAction(_ animated: Bool, state: String) {
        if let action = actionsCompleted.last {
            var duration: TimeInterval
            
            if animated {
                duration = throwSpeed
            } else {
                duration = 0
            }
            
            var undo: SKAction
            undo = SKAction.move(to: action.initialPosition, duration: duration)
            
            let bubbleToRecover = action.bubble
            
            if throwOverBubbles == true {
                action.bubble.physicsBody = nil
                action.bubble.zPosition = 10
            }
            
            addBubble(bubbleToRecover)
            actionsCompleted.removeLast()
            
            bubbleToRecover.run(undo, completion: {
                let keyword = bubbleToRecover.id.replacingOccurrences(of: "#", with: "")
                FirebaseKeywordManager.sharedInstance.removeKeyword(keyword, type: state)
                
                bubbleToRecover.setUpPhysicsBody()
                bubbleToRecover.zPosition = 1
                
                let view = MessageView.viewFromNib(layout: .StatusLine)
                view.configureDropShadow()
                view.configureTheme(.error)
                view.configureContent(body: bubbleToRecover.id)
                
                SwiftMessages.hideAll()
                SwiftMessages.show(view: view)
            })
        } else {
            print("NO MORE ACTIONS TO UNDO")
        }
    }
    
    func moveBubble(_ bubble: Bubble, toY: CGFloat, animated: Bool) {
        var move: SKAction
        move = SKAction.moveTo(y: position.y, duration: throwSpeed)
        
        if throwOverBubbles == true {
            bubble.physicsBody = nil
            bubble.zPosition = 10
        }
        
        bubble.run(move, completion: {
            bubble.setUpPhysicsBody()
            bubble.zPosition = 1
        })
    }
    
    func addActionCompleted(_ action: Action) {
        actionsCompleted.append(action)
    }

    func removeAllActionsCompleted() {
        actionsCompleted.removeAll()
    }
    
    @objc fileprivate func draggingStarted() {
        touchedBubble?.physicsBody = nil
        touchedBubble?.zPosition = 10
        touchedBubble?.scale(.in)
    }
    
    fileprivate func draggingStoped() {
        touchedBubble?.setUpPhysicsBody()
        touchedBubble?.zPosition = 1
        touchedBubble?.scale(.out)
    }
    
}
