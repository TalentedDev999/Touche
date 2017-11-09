//
//  BubblesScene.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/16/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import SpriteKit

//extension Range {
//    func randomElement() -> Iterator.Element? {
//        let elementsCount = count as! Int
//        let randomIndex = Int(arc4random_uniform(UInt32(elementsCount)))
//        let jumpDistance = randomIndex as! Iterator.Element.Distance
//        return <#T##Collection corresponding to your index##Collection#>.index(first?, offsetBy: jumpDistance)
//    }
//}

enum Directions {
    case top
    case bottom
    case left
    case right
}

struct Action {
    let direction: Directions
    let initialPosition: CGPoint
    let bubble: Bubble
}

class BubblesScene: SKScene {

    var bubbleDelegate: BubbleDelegate?

    // Initial Scene setup
    fileprivate let throwDirections: [Directions]
    fileprivate let throwOverBubbles: Bool!
    fileprivate let throwSpeed: TimeInterval!

    fileprivate var bubbles = [Bubble]()
    fileprivate var bubblesLimit = 30

    fileprivate var gravityField: SKFieldNode!
    fileprivate var centerPoint: CGPoint!

    fileprivate var touchedBubble: Bubble?
    fileprivate var touchedBubbleId: String?

    fileprivate var velocity = CGPoint.zero

    fileprivate var lastTouch: CGPoint?

    var touchStartTime: TimeInterval?
    var timer: Timer?

    fileprivate var actionsCompleted = [Action]()

    // MARK: - Methods

    init(size: CGSize, throwDirections: [Directions], throwOver: Bool, throwSpeed: TimeInterval) {
        self.throwDirections = throwDirections
        self.throwOverBubbles = throwOver
        self.throwSpeed = throwSpeed
        super.init(size: size)

        gravitySetup()
        fireBubbleCountEvent()
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

    func uuids() -> [String] {
        return self.bubbles.map({ $0.id })
    }

    func addBubble(_ bubble: Bubble, center: Bool = false) {
        Utils.executeInMainThread({ [weak self] in
            // if the bubble already exists or limit reached, do not insert it, except for locals
            if !center && self?.bubbles.count == self?.bubblesLimit {
                return
            }

            if self?.findBubbleById(bubble.id) == nil {
                self?.bubbles.append(bubble)

                Utils.executeInMainThread { [weak self] in
                    self?.addChild(bubble)
                    self?.fireBubbleCountEvent()
                }

                // Log Bubble seen
                let targetUUID = bubble.id
                let eventId = FirebaseBankManager.ProductIds.Bubble
                AnalyticsManager.sharedInstance.logEventWith(targetUUID!, eventId: eventId)
            }
        })

    }

    func count() -> Int {
        return self.bubbles.count
    }

    func fireBubbleCountEvent() {
        let bubbleCountEvent = EventNames.BubbleCount.didOccur
        MessageBusManager.sharedInstance.postNotificationName(bubbleCountEvent, object: ["count": bubbles.count] as AnyObject)
    }


    func removeBubble(_ bubble: Bubble) {
        if let index = bubbles.index(of: bubble) {
            bubbles.remove(at: index)
        }

        Utils.executeInMainThread { [weak self] in
            bubble.removeFromParent()

            self?.fireBubbleCountEvent()
        }
    }

    func numOfBubbles() -> Int {
        return self.bubbles.count
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

            let touchedNode = atPoint(location)
            guard let parentNode = touchedNode.parent as? Bubble else {
                return
            }

            touchedBubble = parentNode
            touchedBubbleId = touchedBubble?.id

            touchStartTime = event?.timestamp

            timer = Timer.scheduledTimer(timeInterval: 0.15, target: self, selector: #selector(BubblesScene.draggingStarted), userInfo: nil, repeats: false)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let location = touch.location(in: self)
        touchedBubble?.position = location
        let touchedNode = atPoint(location)

        guard let lastTouch = self.lastTouch,
              let parentNode = touchedNode.parent as? Bubble
        else {
            return
        }

        velocity.x = lastTouch.x - location.x
        velocity.y = lastTouch.y - location.y

        self.lastTouch = location

        if touchedBubble == parentNode && parentNode.id == touchedBubbleId {
            parentNode.position = location
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        timer?.invalidate()
        timer = nil

        let hasVelocity = abs(velocity.x) > 10.0 || abs(velocity.y) > 10.0

        if let currentTime = event?.timestamp, let startTime = touchStartTime {
            if currentTime - startTime < 0.15 && !hasVelocity {
                bubbleDelegate?.tapOn(touchedBubble)
                touchStartTime = nil
                touchedBubble = nil
                touchedBubbleId = nil

                return
            }
        }

        guard let isScaled = touchedBubble?.scaled else {
            draggingStoped()
            touchedBubble = nil
            touchedBubbleId = nil
            velocity = CGPoint.zero

            return
        }

        if isScaled {
            draggingStoped()

            if hasVelocity {
                detectAction()
            } else {
                touchedBubble = nil
                touchedBubbleId = nil
                //print("Just moved the bubble")
            }
        } else {
            if hasVelocity {
                detectAction()
            } else {
                touchedBubble = nil
                touchedBubbleId = nil
            }
        }
    }

    fileprivate func detectAction() {
        guard let bubble = touchedBubble else {
            touchedBubbleId = nil
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
            performAction(Action(direction: dir, initialPosition: bubble.position, bubble: bubble))
        } else {
            touchedBubble = nil
            touchedBubbleId = nil
            velocity = CGPoint.zero
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

        touchedBubble = nil
        touchedBubbleId = nil
        velocity = CGPoint.zero

        Utils.executeInMainThread {
            action.bubble.run(move!, completion: {
                () -> Void in
                self.bubbleDelegate?.didAction(action)
            })
        }
    }

    func undoLastAction(animated: Bool) {
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
                FirebasePeopleManager.sharedInstance.unhide(bubbleToRecover.id)

                bubbleToRecover.setUpPhysicsBody()
                bubbleToRecover.zPosition = 1
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
