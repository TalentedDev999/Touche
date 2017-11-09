//
//  DMSwipeCardsView.swift
//  Pods
//
//  Created by Dylan Marriott on 18/12/16.
//
//

import Foundation
import UIKit
import Cupcake
import SwiftRandom
import SwiftyTimer
import SwiftyJSON
import Walker
import NVActivityIndicatorView

public enum SwipeMode {
    case left
    case right
}

public protocol DMSwipeCardsViewDelegate: class {
    func swipedLeft(_ object: Any)

    func swipedRight(_ object: Any)

    func cardTapped(_ object: Any)

    func cardUp(_ object: Any)

    func cardDown(_ object: Any)

    func reachedEndOfStack()
}

public class DMSwipeCardsView<Element>: UIView {

    public weak var delegate: DMSwipeCardsViewDelegate?
    public var bufferSize: Int = 2

    fileprivate let viewGenerator: ViewGenerator
    fileprivate let overlayGenerator: OverlayGenerator?
    fileprivate var allCards = [Element]()
    fileprivate var loadedCards = [DMSwipeCard]()

    var isPaused: Bool = false

    public typealias ViewGenerator = (_ element: Element, _ frame: CGRect) -> (UIView)
    public typealias OverlayGenerator = (_ mode: SwipeMode, _ frame: CGRect) -> (UIView)

    public init(frame: CGRect,
                viewGenerator: @escaping ViewGenerator,
                overlayGenerator: OverlayGenerator? = nil) {
        self.overlayGenerator = overlayGenerator
        self.viewGenerator = viewGenerator
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
    }

    override private init(frame: CGRect) {
        fatalError("Please use init(frame:,viewGenerator)")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("Please use init(frame:,viewGenerator)")
    }

    public func addCards(_ elements: [Element], onTop: Bool = false) {
        if elements.isEmpty {
            return
        }

        self.isUserInteractionEnabled = true

        if onTop {
            for element in elements.reversed() {
                allCards.insert(element, at: 0)
            }
        } else {
            for element in elements {
                allCards.append(element)
            }
        }

        if onTop && loadedCards.count > 0 {
            for cv in loadedCards {
                cv.removeFromSuperview()
            }
            loadedCards.removeAll()
        }

        for element in elements {
            if loadedCards.count < bufferSize {
                let cardView = self.createCardView(element: element)

                cardView.isHidden = true

                Utils.executeInMainThread {
                    if self.loadedCards.isEmpty {
                        self.addSubview(cardView)
                    } else {
                        self.insertSubview(cardView, belowSubview: self.loadedCards.last!)
                    }
                }

                self.loadedCards.append(cardView)
            }
        }

    }

    func swipeTopCardRight() {
        if let top = self.loadedCards.first {
            top.rightAction()
        }
    }

    func swipeTopCardLeft() {
        if let top = self.loadedCards.first {
            top.leftAction()
        }
    }

    func clear() {
        loadedCards = [DMSwipeCard]()
        allCards = [Element]()

        Utils.executeInMainThread {
            self.subviews.forEach({ $0.removeFromSuperview() })
        }
    }

    func stop() {
        if let card: DMSwipeCard = self.loadedCards.first {
//            Utils.executeInMainThread {
//                if let spb = card.toucheCard!.spb {
//                    spb.isPaused = true
//                    self.pauseLayer(layer: card.toucheCard!.backgroundImage.layer)
//                }
//            }
        }
    }

    func pauseLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }

    func resumeLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }

    func start() {



    }

    func isLastCard() -> Bool {
        return self.loadedCards.count == 0
    }

    func hold() {
        if let card: DMSwipeCard = self.loadedCards.first, let toucheCard = card.toucheCard {
            self.stop()
            self.isPaused = true
        }
    }

    func run() {
        if let card: DMSwipeCard = self.loadedCards.first, let toucheCard = card.toucheCard {
            self.start()
            self.isPaused = false
        }
    }

    func pause() {
        if let card: DMSwipeCard = self.loadedCards.first, let toucheCard = card.toucheCard {
            if self.isPaused {
                self.run()
            } else {
                self.hold()
            }
        }
    }

    func unblur() {
        if let card: DMSwipeCard = self.loadedCards.first, let toucheCard = card.toucheCard {
            toucheCard.blurEffectView.isHidden = true
        }
    }

    func uuid() -> String? {
        if let card: DMSwipeCard = self.loadedCards.first, let toucheCard = card.toucheCard {
            return (card.obj as! JSON)["uuid"].stringValue
        }
        return nil
    }

    func profile() -> JSON? {
        if let card: DMSwipeCard = self.loadedCards.first, let toucheCard = card.toucheCard {
            return (card.obj as! JSON)
        }
        return nil
    }

    func hideTagList() {
        if let card: DMSwipeCard = self.loadedCards.first, let toucheCard = card.toucheCard {
            animate(toucheCard.tagListView, duration: 0.2, curve: .easeOut) {
                $0.alpha = 0.0
                $0.y = $0.frame.origin.y - 10
            }.then {
                toucheCard.tagListView.isHidden = true
            }
        }
    }

    func hideChrome() {
        hideTagList()
    }

    func showTagList() {
        if let card: DMSwipeCard = self.loadedCards.first, let toucheCard = card.toucheCard {
            toucheCard.tagListView.isHidden = false
            animate(toucheCard.tagListView, duration: 0.2, curve: .easeIn) {
                $0.alpha = 1.0
                $0.y = $0.frame.origin.y + 10
            }
        }
    }

    func showChrome() {
        showTagList()
    }

//    func spb() -> SegmentedProgressBar? {
//        if let card: DMSwipeCard = self.loadedCards.first, let toucheCard = card.toucheCard, let spb = toucheCard.spb {
//            return spb
//        }
//        return nil
//    }

    func topCard() -> DMSwipeCard? {
        if let card: DMSwipeCard = self.loadedCards.first {
            return card
        }
        return nil
    }
}

extension DMSwipeCardsView: DMSwipeCardDelegate {
    func cardSwipedLeft(_ card: DMSwipeCard) {
        self.handleSwipedCard(card)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            self.delegate?.swipedLeft(card.obj)
            self.loadNextCard()
        }
    }

    func cardSwipedRight(_ card: DMSwipeCard) {
        self.handleSwipedCard(card)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            self.delegate?.swipedRight(card.obj)
            self.loadNextCard()
        }
    }

    func cardTapped(_ card: DMSwipeCard) {
        self.delegate?.cardTapped(card.obj)
    }

    func cardUp(_ card: DMSwipeCard) {
        self.delegate?.cardUp(card.obj)
    }

    func cardDown(_ card: DMSwipeCard) {
        self.delegate?.cardDown(card.obj)
    }
}

extension DMSwipeCardsView {
    fileprivate func handleSwipedCard(_ card: DMSwipeCard) {

        if let first = self.loadedCards.first {
            self.loadedCards.removeFirst()
            self.allCards.removeFirst()
            if self.allCards.isEmpty {
                self.isUserInteractionEnabled = false
            }
        }

//        if self.allCards.count - self.loadedCards.count == 0 {
//            self.delegate?.reachedEndOfStack()
//        }
    }

    fileprivate func loadNextCard() {
        if self.allCards.count - self.loadedCards.count > 0 {
            let next = self.allCards[loadedCards.count]
            let nextView = self.createCardView(element: next)
            self.loadedCards.append(nextView)
            if let below = self.loadedCards.last {
                nextView.isHidden = true
                self.insertSubview(nextView, belowSubview: below)
            } else {
                self.addSubview(nextView)
            }
        } else {
            print("self.allCards.count=\(self.allCards.count),self.loadedCards.count=\(self.loadedCards.count)")
        }
    }

    fileprivate func createCardView(element: Element) -> DMSwipeCard {
        let cardView = DMSwipeCard(frame: self.bounds)
        cardView.delegate = self
        cardView.obj = element
        let sv = self.viewGenerator(element, cardView.bounds)
        cardView.toucheCard = sv as! ToucheCard

        VStack(
                "<-->",
                HStack(
                        cardView.toucheCard!.tagListView.pin(.w(self.frame.width)),
                        "<-->"
//                        Button.onClick({ _ in
//                            if let uuid = self.uuid() {
//                                //NotificationCenter.default.post(name: NSNotification.Name("openChat"), object: uuid)
//                                NotificationCenter.default.post(name: NSNotification.Name("openProfile"), object: uuid)
//                            }
//                        }).img("004-chat").tint("#D40265").bg("#000,0.5").padding(10).radius(-1).pin(.wh(50, 50))
//                        , 10
                ).pin(.wh(self.frame.width, 100)),
                10
        ).embedIn(sv, 0, 0, 0, 0)


        cardView.addSubview(sv)
        animate(cardView, duration: 0.2, curve: .easeOut) {
            $0.alpha = 1.0
        }

        cardView.leftOverlay = self.overlayGenerator?(.left, cardView.bounds)
        cardView.rightOverlay = self.overlayGenerator?(.right, cardView.bounds)
        cardView.configureOverlays()
        return cardView
    }
}