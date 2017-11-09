//
//  ProfileKeywordsVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/4/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import SpriteKit


class ProfileKeywordsVC: UIViewController, BubbleDelegate {

    // MARK: - Variables
    
    fileprivate var skView: SKView!
    fileprivate var keywordScene: KeywordScene!

    fileprivate var keywordsList = [String]() {
        didSet {
            if keywordsList.count > 15 {
                for _ in 0..<15 {
                    addRandomKeywordToScene()
                }
            } else {
                for _ in 0..<keywordsList.count - 1 {
                    addRandomKeywordToScene()
                }
            }
        }
    }
    
    var lastActionBubble: Bubble?
    
    struct State {
        static let Me = FirebaseKeywordManager.Database.Profile.KeywordType.me
        static let You = FirebaseKeywordManager.Database.Profile.KeywordType.you
        static let Like = FirebaseKeywordManager.Database.Profile.KeywordType.like
        static let Dislike = FirebaseKeywordManager.Database.Profile.KeywordType.dislike
    }
    
    fileprivate var currentState = State.Me {
        didSet {
            keywordScene.removeAllActionsCompleted()
        }
    }
    
    fileprivate var stateImage = [String:UIImage]()
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.navigationControllerSetup(navigationController)
        Utils.navigationItemSetup(navigationItem)
        initLeftNavigationItem()
        
        // SpriteKit Setup
        spriteKitViewSetup()

        //buildListMenu()

        getKeywords()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keywordScene.startScene()
        refreshKeywords()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keywordScene.stopScene()
    }

    
    // MARK: - Helper Methods
    
    fileprivate func initLeftNavigationItem() {
        let leftButtonImage = UIImage(named: ToucheApp.Assets.backButtonItem)
        let leftButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(ProfileKeywordsVC.tapOnBack))
        leftButtonItem.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = leftButtonItem
    }
    
    // MARK: - List Menu
    
//    fileprivate func buildListMenu() {
//        if menu != nil {
//            menu.removeFromSuperview()
//        }
//        /*
//        let meImage = UIImage(named: ToucheApp.Assets.Keyword.me)
//        let youImage = UIImage(named: ToucheApp.Assets.Keyword.you)
//        let likeImage = UIImage(named: ToucheApp.Assets.Keyword.like)
//        let dislikeImage = UIImage(named: ToucheApp.Assets.Keyword.dislike)
//
//        stateImage[State.Me] = meImage
//        stateImage[State.You] = youImage
//        stateImage[State.Like] = likeImage
//        stateImage[State.Dislike] = dislikeImage
//        */
//
//        let menuEntries: [EliminationMenu.Item] = [
//            /*EliminationMenu.Item(value: State.Me, title: "", icon: meImage),
//            EliminationMenu.Item(value: State.You, title: "", icon: youImage),
//            EliminationMenu.Item(value: State.Like, title: "", icon: likeImage),
//            EliminationMenu.Item(value: State.Dislike, title: "", icon: dislikeImage)*/
////            EliminationMenu.Item(value: State.Me, title: "💪", icon: nil),
////            EliminationMenu.Item(value: State.You, title: "😍", icon: nil),
////            EliminationMenu.Item(value: State.Like, title: "👍", icon: nil),
////            EliminationMenu.Item(value: State.Dislike, title: "👎", icon: nil)
//        ]
//
//        menu = EliminationMenu.createMenu(withItems: menuEntries, inView: self.view, aligned: .topRight, margin: CGPoint(x: 16, y: 8)) {
//            [weak self] (item) in
//            if let listId = item.value as? String {
//                self?.currentState = listId
//                print("CURRENT STATE: \(listId)")
//            }
//        }
//
//        menu.font = UIFont.boldSystemFont(ofSize: 35)
//        menu.color = UIColor.white
//
//        menu.setup()
//    }
    
    // MARK: - SpriteKit Methods
    
    fileprivate func spriteKitViewSetup() {
        skView = view as! SKView
        skView.ignoresSiblingOrder = true
        peopleSceneSetup()
    }

    fileprivate func peopleSceneSetup() {
        keywordScene = KeywordScene(size: view.bounds.size, throwDirections: [.top, .bottom], throwOver: true, throwSpeed: 0.1)
        keywordScene.bubbleDelegate = self
        keywordScene.scaleMode = .aspectFill
        keywordScene.backgroundColor = UIColor.black
        addBackgroundToScene(keywordScene, imageName: ToucheApp.bg)
        
        skView.presentScene(keywordScene)
    }

    fileprivate func addBackgroundToScene(_ scene: KeywordScene, imageName: String) {
        let bgImage = SKSpriteNode()
        bgImage.anchorPoint = CGPoint(x: 0, y: 1)
        bgImage.position = CGPoint(x: 0, y: scene.size.height)
        bgImage.texture = SKTexture(imageNamed: imageName)
        bgImage.aspectFillToSize(view.frame.size)
        
        Utils.executeInMainThread { 
            scene.addChild(bgImage)
        }
    }

    
    // MARK: - Undo Last Action
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (event?.subtype == UIEventSubtype.motionShake) {
            undoLastAction()
        }
    }

    fileprivate func undoLastAction() {
        keywordScene.undoLastAction(true, state: currentState)
    }

    
    // MARK: - Bubble Delegate
    
    func tapOn(_ bubble: Bubble?) {
        
    }
    
    func didAction(_ action: Action) {
        lastActionBubble = action.bubble
        
        if let keywordBubble = action.bubble as? KeywordBubble {
//            let view = MessageView.viewFromNib(layout: .StatusLine)
//            view.configureDropShadow()
//            view.configureContent(body: keywordBubble.id)
            
            switch action.direction {
            case .top:
                print("Keyword ignored, adding a new one")
//                view.configureTheme(.Error)
                keywordScene.removeBubble(keywordBubble)
                addRandomKeywordToScene()
                SoundManager.sharedInstance.playSound(SoundManager.Sounds.boomerangFly)
                
            case .bottom:
                keywordScene.addActionCompleted(action)
//                view.configureTheme(.Success)
                let keyword = keywordBubble.id.replacingOccurrences(of: "#", with: "")
                FirebaseKeywordManager.sharedInstance.setKeyword(keyword, type: currentState)
                refreshKeywords()
                SoundManager.sharedInstance.playSound(SoundManager.Sounds.pauseMenuSave)

            default:
                break
            }
            
//            SwiftMessages.hideAll()
//            SwiftMessages.show(view: view)

        }
    }
    
    // MARK: - Selectors

    @IBAction func tapOnRefresh(_ sender: AnyObject) {
        refreshKeywords()
    }
    
    func tapOnBack() {
        SoundManager.sharedInstance.playSound(SoundManager.Sounds.boomerangFly)
        navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: - Methods
    
    fileprivate func refreshKeywords() {
        keywordScene.removeAllBubbles()

        if keywordsList.count > 15 {
            for _ in 0..<15 {
                addRandomKeywordToScene()
            }
        } else {
            if keywordsList.count > 0 {
                for _ in 0..<keywordsList.count - 1 {
                    addRandomKeywordToScene()
                }
            }
        }
    }
    
    fileprivate func getKeywords() {
        FirebaseKeywordManager.sharedInstance.getKeywordsList { [weak self] (snapshot) in
            if let snapshotDict = snapshot?.value as? [String:Int] {
                var keyList = [String]()
                for key in snapshotDict {
                    keyList.append("#"+key.0)
                }
                self?.keywordsList = keyList
            }
        }
    }

    fileprivate func addRandomKeywordToScene(_ position: CGPoint? = nil) {
        let randomIndex = Int(arc4random_uniform(UInt32(keywordsList.count - 1)))
        let key = keywordsList[randomIndex]
        addKeyword(key, position: position)
    }
    
    fileprivate func addKeyword(_ text: String, position: CGPoint?) {
        let fontColor = UIColor.white
        let backgroundColor = Utils.darkBlueColorTouche
        let lineWidth:CGFloat = 10
        let cornerRadius:CGFloat = 10

        let label = SKLabelNode(text: text)
        label.fontName = ToucheApp.Fonts.Light.montserrat
        label.fontSize = 25
        label.fontColor = fontColor
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        
        let labelWidth = label.frame.width
        let maxWidth = Utils.screenWidth * 2 / 3
        
        let height: CGFloat = 40
        var width = labelWidth + 20
        if labelWidth > maxWidth {
            width = maxWidth
            adjustLabelFontSizeToFitRect(label, rect: CGRect(x: 0, y: 0, width: width - lineWidth, height: height - lineWidth))
        }
        
        let keywordSize = CGSize(width: width + lineWidth, height: height + lineWidth)
        
        let keywordBubble = KeywordBubble(size: keywordSize,
                                          backgroundColor: backgroundColor,
                                          lineWidth: lineWidth,
                                          cornerRadius: cornerRadius,
                                          scaleOptions: ScaleOptions(factor: 1, animationLength: 0.1))

        if let pos = position {
            keywordBubble.position = pos
        } else {
            keywordBubble.position = Utils.randomPositionOnCircle(Float(Utils.screenWidth), center: Utils.screenCenter)
        }

        keywordBubble.id = text
        
        keywordBubble.addChild(label)
        
        keywordScene.addBubble(keywordBubble)
    }
    
    fileprivate func adjustLabelFontSizeToFitRect(_ labelNode:SKLabelNode, rect:CGRect) {
        let scalingFactor = min(rect.width / labelNode.frame.width, rect.height / labelNode.frame.height)
        labelNode.fontSize *= scalingFactor
    }
}
