//
//  GameVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 8/30/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import Firebase
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class GameVC: UIViewController {

    // MARK: - Properties

    fileprivate let initialImageTime:Double = 1
    fileprivate let initialGameTime = 30
    fileprivate var clock:Timer?
    fileprivate var gameStarted = false
    fileprivate var jokerAvailable = true
    fileprivate var lastDraggingDirection:String?
    fileprivate var historyDelegate:HistoryDelegate!
    fileprivate var messageTypeDelegate:MessageTypeDelegate!
    fileprivate var swipeUpGesture:UISwipeGestureRecognizer?


    let cardsLimit = 1

    var imageCollectionViewDelegate:ImageCollectionViewDelegate!

    var showActionBar = false
    var gameModel:GameModel!
    var gamePoints:Int = 0 {
        didSet {
            pointsLabel.text = "💎 " + String(gamePoints)
            updateActionsAvailable()
        }
    }
    var actionsToSend = [ActionModel]() { didSet { updateActionsAvailable() } }
    var actionsAvailable = [ActionModel]() { didSet { actionCollectionView.reloadData() } }

    var timeLeft = 0 {
        didSet {
            timeLabel.text = "🕒 " + String(timeLeft)

            if timeLeft == 0 {
                endGame()
            }
        }
    }

    var actionsHistory = [ActionModel]() {
        didSet {
            if actionsHistory.count > 0 {
                isMyTurnToReact = actionsHistory.last?.senderUUID != UserManager.sharedInstance.toucheUUID
            }
        }
    }

    var cardsModel = [Card]() {
        didSet {
            var alpha:CGFloat = 0.3
            if cardsModel.count < cardsLimit {
                alpha = 1
                showHandAnimation()
            } else {
                stopHandAnimation()
            }

            Utils.executeInMainThread({ [unowned self] in
                UIView.animate(withDuration: Utils.animationDuration, animations: {
                    self.actionCollectionView.alpha = alpha
                })
            })
        }
    }

    fileprivate var isMyTurnToReact = false {
        didSet {
            if isMyTurnToReact {
                showReactionTime()
            }
        }
    }

    @IBOutlet weak var timeLabel: UILabel! { didSet { timeLabel.text = "" } }
    @IBOutlet weak var pointsLabel: UILabel! { didSet { pointsLabel.text = "" } }

    @IBOutlet weak var historyCollectionView: UICollectionView!
    @IBOutlet weak var cardsView: UIView! { didSet { cardsView.clipsToBounds = true } }

    @IBOutlet weak var messageTypeCollectionView: UICollectionView!
    @IBOutlet weak var actionCollectionView: UICollectionView! {
        didSet {
            actionCollectionView.dataSource = self
            actionCollectionView.delegate = self
        }
    }
    @IBOutlet weak var imageCollectionView: UICollectionView!

    @IBOutlet weak var actionHand: UILabel!

    @IBOutlet weak var opponentAvatar: UIImageView!
    @IBOutlet weak var opponentTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var opponentLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var oponnentBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var opponentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var opponentWidthConstraint: NSLayoutConstraint!

    @IBOutlet var arrows: [UILabel]!


    // MARK: Init Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        initCollectionsView()
        initOpponentAvatar()

        UserManager.sharedInstance.isPlaying = true

        Utils.delay(initialImageTime) { [unowned self] in
            self.initGame()
        }


    }

    deinit {
        print("GameVC DeInit")
        stopObservingActions()

        UserManager.sharedInstance.isPlaying = false

        // make the bubble re-appear on people screen
        FirebaseManager.sharedInstance.refreshLocation()
    }

    fileprivate func initCollectionsView() {
        messageTypeDelegate = MessageTypeDelegate(collectionView: messageTypeCollectionView, delegate: self)
        imageCollectionViewDelegate = ImageCollectionViewDelegate(collectionView: imageCollectionView, delegate: self)

        imageCollectionView.alpha = 0
        imageCollectionView.isUserInteractionEnabled = false
        actionCollectionView.alpha = 1
        actionCollectionView.isUserInteractionEnabled = true
    }

    fileprivate func initGame() {
        animateOpponentAvatar()

        //historyDelegate = HistoryDelegate(collectionView: historyCollectionView)
        //initLeftNavigationItem()
        //initImageViews()

        initActionBar()
        initArrows()
        addExitGameGesture()

        getActionsToSend()
        observeActions()
    }

    fileprivate func animateOpponentAvatar() {
        Utils.executeInMainThread { [unowned self] in
            UIView.animate(withDuration: Utils.animationDuration, animations: {
                self.view.removeConstraint(self.oponnentBottomConstraint)
                self.view.removeConstraint(self.opponentLeadingConstraint)
                self.view.removeConstraint(self.opponentTrailingConstraint)
                self.opponentAvatar.addConstraint(self.opponentWidthConstraint)
                self.opponentAvatar.addConstraint(self.opponentHeightConstraint)

                self.view.layoutIfNeeded()
                self.opponentAvatar.layoutIfNeeded()
                self.timeLabel.layoutIfNeeded()

                self.opponentAvatar.circle()
            })
        }
    }

    fileprivate func initLeftNavigationItem() {
        let leftButtonImage = UIImage(named: ToucheApp.Assets.backButtonItem)
        let leftButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(GameVC.tapOnBack))
        leftButtonItem.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = leftButtonItem
    }

    fileprivate func initActionBar() {
        if showActionBar {
            showHandAnimation()
            actionCollectionView.alpha = 1
            actionHand.alpha = 1
        } else {
            stopHandAnimation()
            actionCollectionView.alpha = 0
            actionHand.alpha = 0
        }
    }

    fileprivate func initArrows() {
        for arrow in arrows {
            arrow.alpha = 0
        }
    }

    fileprivate func initOpponentAvatar() {
        PhotoManager.sharedInstance.getAvatarImageFor(gameModel.toUUID) { [unowned self] (image) in
            self.opponentAvatar.image = image
        }
    }

    fileprivate func getActionsToSend() {

    }

    fileprivate func observeActions() {

    }

    fileprivate func observeReactionsFor(_ gameId:String, actionId:String) {

    }

    fileprivate func observeDraggingFor(_ gameId:String, actionId:String) {

    }

    fileprivate func stopObservingActions() {

    }

    // MARK: - Helper Methods

    fileprivate func handleCardReaction(_ actionId:String, direction:String) {
        for (index, card) in cardsModel.enumerated() {
            if actionId == card.actionId {
                updateHistoryBarWithReaction(actionId, direction: direction)
                removeCardFromReaction(index, direction: direction)
            }
        }
    }

    fileprivate func removeCardFromReaction(_ cardIndex:Int, direction:String) {
        let card = cardsModel[cardIndex]

        let horizontalCenter = Utils.screenWidth / 2
        let verticalCenter = Utils.screenHeight / 2

        var finalPos = CGPoint.zero

        switch direction {

        case ReactionModel.Direction.Top:
            cardsView.bringSubview(toFront: card)
            finalPos = CGPoint(x: horizontalCenter, y: -card.height)

        case ReactionModel.Direction.RightTop:
            cardsView.bringSubview(toFront: card)
            finalPos = CGPoint(x: Utils.screenWidth + card.width , y: verticalCenter - card.height)

        case ReactionModel.Direction.Right:
            cardsView.bringSubview(toFront: card)
            finalPos = CGPoint(x: Utils.screenWidth + card.width , y: verticalCenter)

        case ReactionModel.Direction.RightBottom:
            cardsView.bringSubview(toFront: card)
            finalPos = CGPoint(x: Utils.screenWidth + card.width , y: verticalCenter + card.height)

        case ReactionModel.Direction.LeftTop:
            cardsView.bringSubview(toFront: card)
            finalPos = CGPoint(x: -card.width, y: verticalCenter - card.height)

        case ReactionModel.Direction.Left:
            cardsView.bringSubview(toFront: card)
            finalPos = CGPoint(x: -card.width, y: verticalCenter)

        case ReactionModel.Direction.LeftBottom:
            cardsView.bringSubview(toFront: card)
            finalPos = CGPoint(x: -card.width, y: verticalCenter + card.height)

        default:
            return
        }

        card.updateIconFor(direction)
        cardsModel.remove(at: cardIndex)
        addSwipeGestureToCard()

        Utils.executeInMainThread {
            UIView.animate(withDuration: Utils.animationDuration, animations: {
                card.alpha = 0
                card.center = finalPos
                }, completion: { (finished) in
                    card.removeFromSuperview()
            })
        }
    }

    fileprivate func getRectionDirection(_ center:CGPoint) -> String {
        let topZone = cardsView.frame.height / 3
        let bottomZone = cardsView.frame.height * 2 / 3

        let rightZone = cardsView.frame.width * 0.6
        let leftZone = cardsView.frame.width * 0.4

        // Top
        if center.y < topZone {
            if center.x < leftZone {
                return ReactionModel.Direction.LeftTop
            }

            if center.x > leftZone && center.x < rightZone {
                return ReactionModel.Direction.Top
            }

            if center.x > rightZone {
                return ReactionModel.Direction.RightTop
            }
        }
        // Middle
        if center.y > topZone && center.y < bottomZone {
            if center.x < leftZone {
                return ReactionModel.Direction.Left
            }

            if center.x > leftZone && center.x < rightZone {
                return ReactionModel.Direction.Empty
            }

            if center.x > rightZone {
                return ReactionModel.Direction.Right
            }
        }
        // Bottom
        if center.y > bottomZone {
            if center.x < leftZone {
                return ReactionModel.Direction.LeftBottom
            }

            if center.x > leftZone && center.x < rightZone {
                return ReactionModel.Direction.Empty
            }

            if center.x > rightZone {
                return ReactionModel.Direction.RightBottom
            }
        }

        return ReactionModel.Direction.Empty
    }

    fileprivate func getPointFromDirection(_ direction:String) -> CGPoint {
        let xCenter = cardsView.center.x
        let yCenter = cardsView.center.y
        let topZone = cardsView.frame.height / 4
        let bottomZone = cardsView.frame.height * 3 / 4
        let rightZone = cardsView.frame.width * 3 / 4
        let leftZone = cardsView.frame.width / 4

        let top = CGPoint(x: xCenter, y: topZone)
        let rightTop = CGPoint(x: rightZone, y: topZone)
        let right = CGPoint(x: rightZone, y: yCenter)
        let rightBottom = CGPoint(x: rightZone, y: bottomZone)
        let center = cardsView.center
        let leftTop = CGPoint(x: leftZone, y: topZone)
        let left = CGPoint(x: leftZone, y: yCenter)
        let leftBottom = CGPoint(x: leftZone, y: bottomZone)

        switch direction {
        case ReactionModel.Direction.Top:
            return top
        case ReactionModel.Direction.RightTop:
            return rightTop
        case ReactionModel.Direction.Right:
            return right
        case ReactionModel.Direction.RightBottom:
            return rightBottom
        case ReactionModel.Direction.LeftTop:
            return leftTop
        case ReactionModel.Direction.Left:
            return left
        case ReactionModel.Direction.LeftBottom:
            return leftBottom
        default:
            return center
        }
    }

    fileprivate func updateHistoryBarWithAction(_ card:Card) {
        let cardIcon = card.getIcon()
        let historyCellModel = HistoryCellModel(actionId: card.actionId, action: cardIcon, reaction: nil)
        historyDelegate.collectionModel.append(historyCellModel)
    }

    fileprivate func updateHistoryBarWithReaction(_ actionId:String, direction: String) {
        var auxAction:ActionModel?
        for action in actionsHistory {
            if action.id == actionId {
                auxAction = action
                break
            }
        }

        if let action = auxAction {
            var reactionIcon:String?

            switch direction {

            case ReactionModel.Direction.Top:
                //reactionIcon = action.reactions.Top
                break

            case ReactionModel.Direction.RightTop:
                //reactionIcon = action.reactions.RightTop
                break

            case ReactionModel.Direction.Right:
                //reactionIcon = action.reactions.Right
                break

            case ReactionModel.Direction.RightBottom:
                //reactionIcon = action.reactions.RightBottom
                break

            case ReactionModel.Direction.LeftTop:
                //reactionIcon = action.reactions.LeftTop
                break

            case ReactionModel.Direction.Left:
                //reactionIcon = action.reactions.Left
                break

            case ReactionModel.Direction.LeftBottom:
                //reactionIcon = action.reactions.LeftBottom
                break

            default:
                return
            }

            if let reactionIcon = reactionIcon {
                historyDelegate.updateHistoryBy(actionId, withReaction: reactionIcon)
            }
        }
    }

    fileprivate func removeActionToSend(_ withName:String) {
        var auxIndex:Int?
        for (index, actionToSend) in actionsToSend.enumerated() {
            if actionToSend.name == withName {
                auxIndex = index
                break
            }
        }

        if auxIndex != nil {
            actionsToSend.remove(at: auxIndex!)
        }
    }

    fileprivate func updateActionsAvailable() {
        var initialValue = 0

        if !gameStarted {
            initialValue = 5
        }

        actionsAvailable.removeAll()
        for action in actionsToSend {
            if Int(action.price) <= gamePoints + initialValue {
                actionsAvailable.append(action)
            }
        }
    }

    // MARK: - UI Methods

    func addExitGameGesture() {
        swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(GameVC.tapOnBack))
        swipeUpGesture!.direction = .up
        cardsView.addGestureRecognizer(swipeUpGesture!)
    }

    func addSentCard(_ card: Card) {
        let cardWidth = card.frame.width
        let cardHeight = card.frame.height

        let initialPosX = cardsView.center.x - cardWidth / 2
        let initialPosY = cardsView.center.y + cardHeight

        cardsModel.append(card)

        card.center = CGPoint(x: initialPosX, y: initialPosY)
        cardsView.addSubview(card)

        animateCard(card)

        //updateHistoryBarWithAction(card)
    }

    func addReceivedCard(_ card: Card) {
        let cardWidth = card.frame.width
        let cardHeight = card.frame.height

        let initialPosX =  cardsView.center.x - cardWidth / 2
        let initialPosY = -cardHeight

        cardsModel.append(card)

        card.center = CGPoint(x: initialPosX, y: initialPosY)
        cardsView.addSubview(card)

        addSwipeGestureToCard()

        animateCard(card)
    }

    fileprivate func computePoints(_ actionPrice:String) {
        if let price = Int(actionPrice) {
            gamePoints += price
        }
    }

    fileprivate func animateCard(_ card:Card) {
        Utils.executeInMainThread { [unowned self] in
            UIView.animate(withDuration: Utils.animationDuration, animations: {
                card.center = CGPoint(x: self.cardsView.center.x , y: self.cardsView.center.y)
                card.transform = CGAffineTransform(rotationAngle: CGFloat(card.getAngle() * M_PI / 180))
            })
        }
    }

    fileprivate func animateCardToInitialPosition(_ card:Card) {
        Utils.executeInMainThread { [unowned self] in
            UIView.animate(withDuration: Utils.animationDuration, animations: {
                card.center = CGPoint(x: self.cardsView.center.x , y: self.cardsView.center.y)
            })
        }
    }

    fileprivate func addSwipeGestureToCard() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(GameVC.handleCardPan(_:)))
        for card in cardsView.subviews {
            card.removeGestureRecognizer(pan)
        }

        if let card = cardsModel.last {
            card.addGestureRecognizer(pan)
        }
    }

    fileprivate func showReactionTime() {
        Utils.executeInMainThread { [unowned self] in
            UIView.animate(withDuration: Utils.animationDuration, delay: 0, options: .repeat, animations: {
                for arrow in self.arrows {
                    arrow.alpha = 1
                }

            }) { (finished) in }

            self.initGameTimer()
        }
    }

    fileprivate func stopReactionAnimation() {
        for arrow in arrows {
            arrow.alpha = 0
            arrow.layer.removeAllAnimations()
        }

        invalidateGameTimer()
    }

    fileprivate func showHandAnimation() {
        actionHand.alpha = 1

        Utils.executeInMainThread { [unowned self] in
            UIView.animate(withDuration: Utils.animationDuration, delay: 0, options: .repeat, animations: {
                self.actionHand.alpha = 0
            }) { (finished) in }

            if self.gameStarted {
                self.initGameTimer()
            }
        }
    }

    fileprivate func stopHandAnimation() {
        actionHand.alpha = 0
        actionHand.layer.removeAllAnimations()

        invalidateGameTimer()
    }

    // MARK: - Events

    fileprivate func actionReceivedFromFirebase(_ snapshot: DataSnapshot) {
        let action = ActionModel(snapshot: snapshot)

        if action.isAValidAction() {
            gameStarted = true

            computePoints(action.price)
            observeReactionsFor(gameModel.gameId, actionId: action.id)

            if action.senderUUID == UserManager.sharedInstance.toucheUUID {
                removeActionToSend(action.name)
            }

            let card = Card(fromAction: action)

            switch action.directionOfReaction {

            case ReactionModel.Direction.Empty:
                actionsHistory.append(action)

                if action.senderUUID != UserManager.sharedInstance.toucheUUID {
                    addReceivedCard(card)
                } else {
                    addSentCard(card)
                    observeDraggingFor(gameModel.gameId, actionId: action.id)
                }

            case ReactionModel.Direction.Top:
                // Disable joker reaction if I already sent it
                if action.senderUUID != UserManager.sharedInstance.toucheUUID {
                    jokerAvailable = false
                }

                break

            case ReactionModel.Direction.RightTop:
                break

            case ReactionModel.Direction.Right:
                break

            case ReactionModel.Direction.RightBottom:
                break

            case ReactionModel.Direction.LeftTop:
                break

            case ReactionModel.Direction.Left:
                break

            case ReactionModel.Direction.LeftBottom:
                break

            default:
                break
            }
        }
    }

    fileprivate func reactionReceivedFromFirebase(_ actionId:String, direction:String) {
        print("Handle reaction received: actionId \(actionId) - reactionReceived: \(direction)")

        for action in actionsHistory {
            if actionId == action.id {

                handleCardReaction(action.id, direction: direction)
                break
            }
        }
    }

    // MARK: - Selectors

    func tapOnBack() {
        clock = nil
        //navigationController?.popViewControllerAnimated(true)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func handleCardPan(_ gesture: UIPanGestureRecognizer) {
        if let card = cardsModel.last {
            switch gesture.state {

            case .changed:
                let newCenter = gesture.translation(in: cardsView)
                gesture.setTranslation(CGPoint.zero, in: cardsView)
                updatingCardWhileDragging(card, newCenter: newCenter)

            case .ended:
                finishedDragging(card)

            default:
                break
            }
        }
    }

    func handleDraggingDirection(_ direction:String) {
        let point = getPointFromDirection(direction)

        cardsModel.last?.updateIconFor(direction)

        Utils.executeInMainThread { [unowned self] in
            UIView.animate(withDuration: Utils.animationDuration / 3, delay: 0, options: .beginFromCurrentState, animations: {
                self.cardsModel.last?.center = point
                }, completion: { (finished) in

            })
        }
    }

    // MARK: - Dragging Methods

    fileprivate func updatingCardWhileDragging(_ card:Card, newCenter:CGPoint) {
        card.center = CGPoint(x: card.center.x + newCenter.x, y: card.center.y + newCenter.y)

        let direction = getRectionDirection(card.center)

        if lastDraggingDirection != direction {
            card.updateIconFor(direction, jokerAvailable: jokerAvailable)

        }

        lastDraggingDirection = direction
    }

    fileprivate func finishedDragging(_ card:Card) {
        let direction = getRectionDirection(card.center)

        if direction == ReactionModel.Direction.Top && !jokerAvailable {
            animateCardToInitialPosition(card)

            return
        }

        if direction != ReactionModel.Direction.Empty {
            if direction == ReactionModel.Direction.Top {
                jokerAvailable = false
            }
            stopReactionAnimation()


        } else {
            animateCardToInitialPosition(card)
        }
    }

    // MARK: - Timer

    func timeCountDown() {
        timeLeft -= 1
    }

    fileprivate func initGameTimer() {
        timeLabel.isHidden = false
        timeLeft = initialGameTime
        if clock == nil {
            clock = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(GameVC.timeCountDown), userInfo: nil, repeats: true)
        }
    }

    fileprivate func invalidateGameTimer() {
        clock?.invalidate()
        clock = nil
        timeLabel.isHidden = true
    }

    fileprivate func endGame() {
        invalidateGameTimer()
        tapOnBack()
    }

}
