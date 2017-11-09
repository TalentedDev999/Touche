//
//  PeopleVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/4/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

import SwiftyJSON
import SpriteKit
import GoogleMobileAds
import MBProgressHUD
import Crashlytics
import PopupDialog
import FBSDKShareKit
import PKHUD
import Emoji
import Foundation
import Cupcake

class PeopleVC: UIViewController, BubbleDelegate, FBSDKAppInviteDialogDelegate, UISearchBarDelegate {

    fileprivate var skView: SKView!
    fileprivate var peopleScene: BubblesScene!

    fileprivate var switchTitle = Utils.localizedString("Games")

//    fileprivate var menu: EliminationMenu!
//    fileprivate var sceneSwitchMenu: EliminationMenu!

    fileprivate var page = 1
    fileprivate var maxPages = 10
    // assumed a default value

    fileprivate var profiles: [String: ProfileModel] = [:]

    fileprivate var hud: MBProgressHUD?

    var counters: ToucheCounters!

    struct State {
        static let Everyone = "everyone"
        static let Likes = "like"
        static let Blocks = "block"
        static let LikesMe = "liked_by"
        static let ViewedMe = "viewed_by"
        static let MostViewed = "most_viewed"
        static let MutualLikes = "mutual_likes"
        static let MyPolygons = "my_polygons"
        static let Viewed = "viewed"
        static let Hides = "hide"
        static let HidesMe = "hidden_by"
        static let BlocksMe = "blocked_by"
    }

    var state: String = State.Everyone {
        didSet {
            if state == State.Everyone {
                switchPeopleSceneButton.isHidden = true
            } else {
                switchPeopleSceneButton.isHidden = false
            }
        }
    }

    var showingBackScene = false {
        didSet {
            /*
            let transition = SKTransition.flipVerticalWithDuration(Utils.animationDuration)

            if showingBackScene {
                Utils.executeInMainThread({
                    [unowned self] in
                    self.skView.presentScene(self.peopleBackScene, transition: transition)
                    self.displayListForSceneSide()
                })
            } else {
                Utils.executeInMainThread({
                    [unowned self] in
                    self.skView.presentScene(self.peopleScene, transition: transition)
                    self.displayListForSceneSide()
                })
            }
            */
        }
    }

    var currentScene: BubblesScene {
        get {
            if showingBackScene {
                return peopleBackScene
            } else {
                return peopleScene
            }
        }
    }

    var peopleBackScene: BubblesScene!

    var lastActionBubble: Bubble?

    let switchPeopleSceneButton = UIButton()
    var auxGameModel: GameModel?

    var balanceUsageLabel: UILabel?


    @IBOutlet weak var switchSceneButton: UIBarButtonItem!


    var currentProfileDetailBubble: Bubble?

    fileprivate var shouldIncrementCycles = true

    var returningFromFacebook = false

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        Utils.navigationControllerSetup(navigationController)
        Utils.navigationItemSetup(navigationItem)

        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true

        // init managers
        FirebasePeopleManager.sharedInstance

        //registerForRefreshNotifications()
        //registerGotoProfileNotifications()
        //registerGotoChatNotifications()
        //registerForListChangeNotifications()
        //registerForProfileChangeNotifications()
        //registerForLifeEvents()
        //registerForBankEvents()
        //registerForBubbleCountNotifications()
        //registerForCyclesEvent()

        registerForPopupNotifications()
        registerForLoginServicesReady()
        registerForLocationNotifications()


        // SpriteKit Setup
        spriteKitViewSetup()
        peopleSceneSetup()
        //peopleBackSceneSetup()


        //buildBalanceLabel()

        PhotoManager.sharedInstance.checkPrimaryPic()

        // Find People
        self.retrievePeople()

        setupCounters()

        setupLayout()

        skView.presentScene(peopleScene)

        //buildSceneSwitchMenu()

        //setupSwitchSceneButton()

        let filterBtn = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(showFacets))
        filterBtn.setFAIcon(icon: .FAFilter, iconSize: 22)
        filterBtn.tintColor = UIColor.gray

        navigationItem.leftBarButtonItems = [filterBtn]

        let mapBtn = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(showMap))
        mapBtn.setFAIcon(icon: .FAMap, iconSize: 22)
        mapBtn.tintColor = UIColor.gray
        let refreshBtn = UIBarButtonItem(title: "️", style: .done, target: self, action: #selector(hideAndRefresh))
        refreshBtn.setFAIcon(icon: .FARefresh, iconSize: 22)
        refreshBtn.tintColor = UIColor.gray
        navigationItem.rightBarButtonItems = [refreshBtn, mapBtn]

    }

    func setupCounters() {
        self.counters = ToucheCounters(frame: self.view.frame)
    }

    private func setupLayout() {
        VStack(
                HStack(
                        20,
                        VStack(
                                counters.pin(.wh(self.view.frame.width, 50))
                        ).gap(10).pin(.w(self.view.frame.width)),
                        20
                ),
                "<-->"
        ).embedIn(self.view, 10, 0, 50, 0)
    }

    func showMap() {

        var onScreen: [String: ProfileModel] = [:]
        for key in self.profiles.keys {
            if self.peopleScene.uuids().contains(key) {
                onScreen[key] = self.profiles[key]
            }
        }

        PopupManager.sharedInstance.showMapPopup(onScreen)
    }


    func showSearchBar() {
        PopupManager.sharedInstance.showFilterPopup()
    }

    func showFacets() {
        let controller = PolygonsFormController()

        let transition = CATransition()
        transition.duration = Utils.animationDuration
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromRight
        self.navigationController?.view.layer.add(transition, forKey: kCATransition)
        self.navigationController?.pushViewController(controller, animated: false)


//        let navigationController = UINavigationController(rootViewController: controller)
//        self.addChildViewController(navigationController)
//        navigationController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//        self.view.addSubview(navigationController.view)
//        navigationController.didMoveToParentViewController(self)
    }


    func showPopup() {

        print("loading next popup...")

//        // Show Upload Pic Popover if the user has not primary picture
//        FirebasePeopleManager.sharedInstance.isPrimaryPicSetted { (hasPrimaryPic) in
//            if !hasPrimaryPic {
//                if PhotoManager.sharedInstance.pixelate {
//                    // todo: offer to invite fb friends
//                    //FacebookManager.sharedInstance.showFBInvite(self)
//                } else {
//                    Utils.executeInMainThread { [unowned self] in
//                        SigninPopoverManager.sharedInstance.showSignInPopover(viewController: self)
//                    }
//                }
//            } else {
//                // todo: ask the backend to give me popup data
//                Utils.executeInMainThread { [unowned self] in
//                    IAPManager.sharedInstance.showUpgradePopover(self)
//                }
//            }
//        }
    }

    public func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable: Any]!) {
        print(results)
    }

    public func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {

    }


    fileprivate func buildBalanceLabel() {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        balanceUsageLabel = UILabel(frame: frame)

        let balance = FirebaseBankManager.sharedInstance.getUsage() ?? 0

        balanceUsageLabel!.text = String(balance)
        balanceUsageLabel!.backgroundColor = UIColor.black
        balanceUsageLabel!.font = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: 32)
        balanceUsageLabel!.textColor = UIColor.white

        // hide counter
        // view.addSubview(balanceUsageLabel!)
        // view.bringSubviewToFront(balanceUsageLabel!)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //buildListMenu()

        if showingBackScene {
            peopleBackScene.startScene()
        } else {
            peopleScene.startScene()
        }

        FirebaseChatManager.sharedInstance.currentNavigationController = navigationController

        // showAds()

        PhotoManager.sharedInstance.checkPrimaryPic()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if showingBackScene {
            peopleBackScene.stopScene()
        } else {
            peopleScene.stopScene()
        }
    }

    deinit {
        print("PeopleVC deinit")
        MessageBusManager.sharedInstance.removeObserver(self)
    }

// MARK: - Methods

//    fileprivate func buildListMenu() {
//
//        if menu == nil {
//            let menuEntries: [EliminationMenu.Item] = [
//                    EliminationMenu.Item(value: State.Everyone, title: "🌎"),
//                    EliminationMenu.Item(value: State.Likes, title: "⭐️"),
//                    EliminationMenu.Item(value: State.MostViewed, title: "🔥"),
//                    EliminationMenu.Item(value: State.MutualLikes, title: "♥️️"),
//                    EliminationMenu.Item(value: State.ViewedMe, title: "👀"),
//                    EliminationMenu.Item(value: State.MyPolygons, title: "📍")
//                    //EliminationMenu.Item(value: State.Hides, title: "", icon: UIImage(named: "hide")),
//                    //EliminationMenu.Item(value: State.Blocks, title: "", icon: UIImage(named: "block"))
//            ]
//
//            menu = EliminationMenu.createMenu(withItems: menuEntries, inView: self.view, aligned: .bottomRight, margin: CGPoint(x: 16, y: 8)) {
//                (item) in
//                if let listId = item.value {
//                    self.state = listId as! String
//                    self.refresh()
//                }
//            }
//
//            menu.font = UIFont.boldSystemFont(ofSize: 35)
//            menu.color = UIColor.white
//
//            menu.setup()
//        }
//
//
//    }

//    fileprivate func buildSceneSwitchMenu() {
//        if sceneSwitchMenu != nil {
//            sceneSwitchMenu.removeFromSuperview()
//        }
//
//        let imageSize = CGSize(width: 70, height: 70)
//        let imageFrontColor = UIColor.white
//        let imageBackColor = UIColor.black
//
//        let peopleSceneImage = UIImage(icon: FAType.faTimes, size: imageSize, textColor: imageFrontColor, backgroundColor: imageBackColor)
//        let peopleBackSceneImage = UIImage(icon: FAType.faTimesCircle, size: imageSize, textColor: imageFrontColor, backgroundColor: imageBackColor)
//
//        let menuEntries: [EliminationMenu.Item] = [
//                EliminationMenu.Item(value: currentScene, title: "", icon: peopleSceneImage),
//                EliminationMenu.Item(value: currentScene, title: "", icon: peopleBackSceneImage)
//        ]
//
//        sceneSwitchMenu = EliminationMenu.createMenu(withItems: menuEntries, inView: self.view, aligned: .topRight, margin: CGPoint(x: 0, y: 80)) {
//            (item) in
//            /*
//            if let currentScene = item.value {
//                self.displayListById(curren as! String)
//                self.state = listId as! String
//            }*/
//        }
//
//        sceneSwitchMenu.font = UIFont.boldSystemFont(ofSize: 32)
//        sceneSwitchMenu.color = UIColor.white
//
//        sceneSwitchMenu.setup()
//    }

// MARK: - Switch People Scene

    fileprivate func setupSwitchSceneButton() {
        let frame = CGRect(x: Utils.screenWidth - 120, y: 25, width: 40, height: 40)
        switchPeopleSceneButton.frame = frame
        let image = UIImage(icon: FAType.FARandom, size: frame.size, textColor: UIColor.white, backgroundColor: UIColor.clear)
        switchPeopleSceneButton.setImage(image, for: UIControlState())
        switchPeopleSceneButton.isHidden = true

        switchPeopleSceneButton.addTarget(self, action: #selector(PeopleVC.switchPeopleSceneHandler(_:)), for: .touchUpInside)

        view.addSubview(switchPeopleSceneButton)
    }

    func switchPeopleSceneHandler(_ sender: UIButton) {
        print("switch button pressed")
        showingBackScene = !showingBackScene
    }

    fileprivate func displayListForSceneSide() {
        switch state {
        case State.Likes:
            displayListById(State.LikesMe)
            self.state = State.LikesMe

        case State.Hides:
            displayListById(State.HidesMe)
            self.state = State.HidesMe

        case State.Blocks:
            displayListById(State.BlocksMe)
            self.state = State.BlocksMe

        case State.LikesMe:
            displayListById(State.Likes)
            self.state = State.Likes

        case State.HidesMe:
            displayListById(State.Hides)
            self.state = State.Hides

        case State.BlocksMe:
            displayListById(State.Blocks)
            self.state = State.Blocks

        default:
            break
        }
    }


// MARK: - SpriteKit

    fileprivate func spriteKitViewSetup() {
        skView = self.view as! SKView
        skView.ignoresSiblingOrder = true
        skView.showsNodeCount = false
    }

    fileprivate func peopleSceneSetup() {
        peopleScene = BubblesScene(size: view.bounds.size, throwDirections: [.top, .bottom], throwOver: true, throwSpeed: 0.1)
        peopleScene.bubbleDelegate = self
        peopleScene.scaleMode = .aspectFill
        peopleScene.backgroundColor = UIColor.clear

        addBackgroundToScene(peopleScene, imageName: ToucheApp.bg)
    }

    fileprivate func peopleBackSceneSetup() {
        peopleBackScene = BubblesScene(size: view.bounds.size, throwDirections: [.top, .bottom], throwOver: true, throwSpeed: 0.1)
        peopleBackScene.bubbleDelegate = self
        peopleBackScene.scaleMode = .aspectFill
        peopleBackScene.backgroundColor = UIColor.clear

        addBackgroundToScene(peopleBackScene, imageName: ToucheApp.bg)
    }

    fileprivate func addBackgroundToScene(_ scene: BubblesScene, imageName: String) {
        let bgImage = SKSpriteNode()
        bgImage.anchorPoint = CGPoint(x: 0, y: 1)
        bgImage.position = CGPoint(x: 0, y: scene.size.height)
        bgImage.texture = SKTexture(imageNamed: imageName)
        bgImage.aspectFillToSize(view.frame.size)

        Utils.executeInMainThread {
            scene.addChild(bgImage)
        }
    }

    func removeCurrentProfileDetailBubble() {
        if let bubble = currentProfileDetailBubble {
            peopleScene.removeBubble(bubble)
        }
    }

    func addCurrentProfileDetailBubble() {
        if let bubble = currentProfileDetailBubble {
            peopleScene.addBubble(bubble)
        }
    }

// MARK: - Notification Registry

    fileprivate func registerForLocationNotifications() {
        let locationChangeSelector = #selector(PeopleVC.locationDidChange)
        let locationChangeEvent = EventNames.Location.newLocationAvailable
        MessageBusManager.sharedInstance.addObserver(self, selector: locationChangeSelector, name: locationChangeEvent)
    }

    fileprivate func registerForRefreshNotifications() {
        let refreshSelector = #selector(PeopleVC.refresh)
        let refreshEvent = EventNames.People.refresh
        MessageBusManager.sharedInstance.addObserver(self, selector: refreshSelector, name: refreshEvent)
    }

    fileprivate func registerGotoProfileNotifications() {
        let gotoProfileSelector = #selector(PeopleVC.gotoProfile)
        let gotoProfileEvent = EventNames.MainTabBar.gotoProfile
        MessageBusManager.sharedInstance.addObserver(self, selector: gotoProfileSelector, name: gotoProfileEvent)
    }

    fileprivate func registerGotoChatNotifications() {
        let gotoChatSelector = #selector(PeopleVC.gotoChat)
        let gotoChatEvent = EventNames.MainTabBar.gotoChat
        MessageBusManager.sharedInstance.addObserver(self, selector: gotoChatSelector, name: gotoChatEvent)
    }

    fileprivate func registerForPopupNotifications() {
        let popupSelector = #selector(PeopleVC.showPopup)
        let popupEvent = EventNames.Popup.showPopup
        MessageBusManager.sharedInstance.addObserver(self, selector: popupSelector, name: popupEvent)
    }

    fileprivate func registerForListChangeNotifications() {
        let listChangeSelector = #selector(PeopleVC.onListChange)
        let listChangeEvent = EventNames.List.didChange
        MessageBusManager.sharedInstance.addObserver(self, selector: listChangeSelector, name: listChangeEvent)
    }

    fileprivate func registerForProfileChangeNotifications() {
        let profileChangeSelector = #selector(PeopleVC.onProfileChange)
        let profileChangeEvent = EventNames.Profile.didChange
        MessageBusManager.sharedInstance.addObserver(self, selector: profileChangeSelector, name: profileChangeEvent)
    }

    fileprivate func registerForLifeEvents() {
        let lifeEventSelector = #selector(PeopleVC.onLifeEvent)
        let lifeEventOccured = EventNames.LifeEvents.didOccur
        MessageBusManager.sharedInstance.addObserver(self, selector: lifeEventSelector, name: lifeEventOccured)
    }

    fileprivate func registerForBubbleCountNotifications() {
        let bubbleCountSelector = #selector(PeopleVC.onBubbleCount)
        let bubbleCountEvent = EventNames.BubbleCount.didOccur
        MessageBusManager.sharedInstance.addObserver(self, selector: bubbleCountSelector, name: bubbleCountEvent)
    }

    fileprivate func registerForLoginServicesReady() {
        let loginServicesReadySelector = #selector(PeopleVC.onLoginServicesReady)
        let loginServicesReadyEvent = EventNames.Login.services_available
        MessageBusManager.sharedInstance.addObserver(self, selector: loginServicesReadySelector, name: loginServicesReadyEvent)
    }

    fileprivate func registerForBankEvents() {
        let usageDidChangeSelector = #selector(PeopleVC.updateUsage)
        let usageDidChangeEvent = EventNames.Bank.usageDidChange
        MessageBusManager.sharedInstance.addObserver(self, selector: usageDidChangeSelector, name: usageDidChangeEvent)

        let overLimitSelector = #selector(PeopleVC.onOverLimitEvent)
        let overLimitEvent = EventNames.Bank.overLimitEvent
        MessageBusManager.sharedInstance.addObserver(self, selector: overLimitSelector, name: overLimitEvent)

    }

    fileprivate func registerForPolygonsNotifications() {
        let freshPolygonsSelector = #selector(PeopleVC.freshPolygons)
        let freshPolygonsEvent = EventNames.Location.freshPolygons
        MessageBusManager.sharedInstance.addObserver(self, selector: freshPolygonsSelector, name: freshPolygonsEvent)
    }

    fileprivate func registerForCyclesEvent() {
        let cyclesDidChangeSelector = #selector(PeopleVC.showAds)
        let cyclesDidChangeEvent = EventNames.Profile.Cycles.cyclesDidChange
        MessageBusManager.sharedInstance.addObserver(self, selector: cyclesDidChangeSelector, name: cyclesDidChangeEvent)
    }

// MARK: People

    func displayListById(_ listId: String) {
        self.retrievePeople(listId)
    }

    func displayList(_ list: List) {
        SoundManager.sharedInstance.playSound(SoundManager.Sounds.wave)
        currentScene.removeAllBubbles()
        for uuid in list.collection {
            self.buildAndAddBubble(uuid)
        }
    }

    func hideAndRefresh() {
        HUD.show(.rotatingImage(UIImage(icon: .FARefresh, size: CGSize(width: 100, height: 100))))
        SoundManager.sharedInstance.playSound(SoundManager.Sounds.wave)

        // hide all existing
        FirebasePeopleManager.sharedInstance.hideMultiple(self.peopleScene.uuids()) {
            // then refresh
            self.displayListById(self.state)
        }
    }

    func refresh() {
        HUD.show(.rotatingImage(UIImage(icon: .FARefresh, size: CGSize(width: 100, height: 100))))
        SoundManager.sharedInstance.playSound(SoundManager.Sounds.wave)

        self.displayListById(self.state)
    }

    func gotoProfile(_ notification: Notification) {
        if let event = notification.object as? [String: String], let uuid = event["uuid"] {
            PhotoManager.sharedInstance.getAvatarImageFor(uuid) { (image) in
                if let img = image {
                    self.showProfile(uuid, image: img)
                } else {
                    self.showProfile(uuid, image: nil)
                }
            }
        }
    }

    func gotoChat(_ notification: Notification) {
        if let event = notification.object as? [String: String], let uuid = event["uuid"] {
            SoundManager.sharedInstance.playSound(SoundManager.Sounds.pauseMenuEquip)
            FirebaseChatManager.sharedInstance.showConversationVCWithUser(uuid, nc: self.navigationController)
        }
    }

/**
 * Retrieve Users filtered by position
 * Fill People Collection with toucheUsers instantiated with data retrieved
 * Update UI with bubbles from People Collection
 */
    func retrievePeople(_ listId: String = State.Everyone) {
        self.peopleScene.removeAllBubbles()
        retrievePeopleFromLambda(listId)
    }


    func retrievePeopleFromLambda(_ listId: String) {

        let lat = CoreLocationManager.sharedInstance.currentLocation?.coordinate.latitude
        let lng = CoreLocationManager.sharedInstance.currentLocation?.coordinate.longitude

        var preset = "nearby"
        if listId != "everyone" {
            preset = listId
        }

        if let latitude = lat, let longitude = lng {
            AWSLambdaManager.sharedInstance.nearbyProfiles(latitude, lon: longitude, preset: preset, completion: {
                (result, exception, error) in

                Utils.executeInMainThread {
                    if HUD.isVisible {
                        HUD.hide(animated: false)
                    }
                }

                if result != nil {
                    let jsonResult = JSON(result!)
                    let uuids = jsonResult[AWSLambdaManager.NearbyProfiles.Response.uuids].arrayValue
                    let profiles = jsonResult[AWSLambdaManager.NearbyProfiles.Response.profiles].arrayValue
                    print("uuids=\(uuids.count)")

                    if uuids.count == 0 {
                        Utils.executeInMainThread {
                            PopupManager.sharedInstance.simplePopup("😓 No results found".translate(), okButtonText: "OK".translate())
                        }
                    } else {
                        // clear cache
                        self.profiles.removeAll()

                        for profile in profiles {
                            let uuid = profile.dictionaryValue["uuid"]!.stringValue
                            let pic = profile.dictionaryValue["pic"]!.stringValue
                            let geohash = profile.dictionaryValue["geo"]!.stringValue
                            var seen: Int64 = Int64(NSDate().timeIntervalSince1970) // defaults to now
                            let profile = ProfileModel(uuid: uuid, pic: pic, seen: seen, status: "", endpointArn: "", geohash: geohash)

                            self.profiles[uuid] = profile

                            self.buildBubble(uuid, profile: profile, center: true)
                        }
                    }
                }

                if error != nil {
                    print(error)
                    return
                }

                if exception != nil {
                    print(exception)
                    return
                }

            })
        }

    }

    func push(_ key: String, center: Bool? = false) {
        if (key != UserManager.sharedInstance.toucheUUID && key != "") {
            FirebasePeopleManager.sharedInstance.getProfile(key) {
                [unowned self] (profile) in
                if profile != nil {
                    if FirebaseBankManager.sharedInstance.consume(FirebaseBankManager.ProductIds.Bubble) {
                        self.buildBubble(key, profile: profile!, center: center)
                    }
                }
            }
        }
    }

    fileprivate func buildAndAddBubble(_ uuid: String) {
        FirebasePeopleManager.sharedInstance.getProfile(uuid) {
            [unowned self] (profile) in
            if profile != nil {
                if FirebaseBankManager.sharedInstance.consume(FirebaseBankManager.ProductIds.Bubble) {
                    self.buildBubble(uuid, profile: profile!)
                }
            }
        }
    }

    func buildBubble(_ key: String, profile: ProfileModel, center: Bool? = false) {
        let toucheUser = ToucheUser()

        toucheUser.userData!.objectId = key

        if let pic = profile.pic {
            toucheUser.userData?.pic = pic
        } else {
            print("pic was null!!!")
            print(key)
        }

        let bubble = PeopleBubble(user: toucheUser, width: 100, scaleOptions: ScaleOptions(factor: 3, animationLength: 0.1))
        if center == true {
            bubble.position = Utils.randomPositionOnCircle(Float(100), center: Utils.screenCenter)
        } else {
            bubble.position = Utils.randomPositionOnCircle(Float(Utils.screenWidth), center: Utils.screenCenter)
        }

        self.peopleScene.addBubble(bubble, center: center!)

    }

    fileprivate func shouldDisplay(_ uuid: String, profile: ProfileModel) -> Bool {
        if profile.seen != nil {
            // calculate freshness
            let lastSeen = Date(timeIntervalSince1970: Double(profile.seen!))
            let timeInterval: Double = lastSeen.timeIntervalSinceNow
            //print("timeInterval=\(timeInterval)s")
            let isFresh: Bool = timeInterval >= -600

            if uuid.range(of: "BOT-") != nil {
                return true
            }

            return isFresh
        }
        return false
    }

/**
 * Retrieve Users filtered by search text
 * Fill Searched Collection with toucheUsers intantiated with data retrieved
 * Update UI with bubbles from Searched Colletion
 */
    fileprivate func retrievePeopleFilteredBy(_ query: String?) {

    }

// MARK: - Shake recognizer

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (event?.subtype == UIEventSubtype.motionShake) {
            undoLastAction()
        }
    }


// MARK: - Selectors
    func locationDidChange() {
        self.retrievePeople()
        self.counters.initialize()
    }

    func startHud() {

    }

    func onLoginServicesReady() {

    }

    func onBubbleCount(_ notification: Notification) {
//        if let event = notification.object as? [String: Int], let count = event["count"] {
//            if state == State.Everyone {
//
//                print(count)
//
//                // if the scene is nearly empty, that meas we should move to the next page
//                if count <= 5 {
//
//                    if (page + 1 < maxPages) {
//                        self.page += 1
//                        self.retrievePeopleFromAlgolia()
//                    } else if (page + 1 == maxPages) {
//                        self.page = 1
//                        if (FirebasePeopleManager.sharedInstance.hasLikesOrHides()) {
//                            FirebasePeopleManager.sharedInstance.dumpHides()
//                            self.retrievePeople()
//                        } else {
//                            self.retrievePeopleFromAlgolia()
//                        }
//                    } else {
//                        print(maxPages)
//                    }
//
//                }
//            }
//        }
    }

    func onLifeEvent(_ notification: Notification) {

        // todo: this stuff will be handled server side


        print("onLifeEvent \(notification)")

        guard let event = notification.object as? [String: String] else {
            return
        }
        guard let uuid = event["uuid"] else {
            return
        }
        guard let lifeEventName = event["lifeEventName"] else {
            return
        }
        guard let timestamp = event["timestamp"] else {
            return
        }


        // Only if the timestamp is less than a minute from now so then display the event!
        if let ts = Double(timestamp) {
            let timestampDate = Date(timeIntervalSince1970: ts / 1000)
            let timeInterval: Double = timestampDate.timeIntervalSinceNow // If interval is earlier than the date this value is negative.

            if timeInterval < 0 && timeInterval >= -60 {


                switch lifeEventName {
                case EventNames.LifeEvents.breakUp:
                    break
                case EventNames.LifeEvents.mutualLike:
                    break
                default:
                    break
                }


            }
        }
    }

    func onProfileChange(_ notification: Notification) {

        print(notification)

        if let event = notification.object as? [String: String], let uuid = event["uuid"], let key = event["key"] {
            if key == FirebasePeopleManager.Database.Profile.pic {
                // if the bubble exists in this view, then...
                if let existingBubble = self.peopleScene.findBubbleById(uuid) {
                    // remove the bubble and re-add it
                    self.peopleScene.removeBubble(existingBubble)
                    self.buildAndAddBubble(uuid)
                }

            }
        }
    }

    func showMutualLikePopover(_ uuid: String) {

        // todo: this popup is a little dumb...
        // todo: let's replace it with something else, server side. like a push notification

    }

    func onListChange(_ notification: Notification) {
        if let event = notification.object as? [String: String] {
            if let listId = event["listId"], let direction = event["direction"], let uuid = event["uuid"] {
                if state == listId {
                    switch direction {
                    case "add":
                        self.buildAndAddBubble(uuid)
                        break
                    case "remove":
                        self.peopleScene.removeBubbleById(uuid)
                        break
                    default:
                        break
                    }
                }

                // if you were blocked by someone while looking at the bubbles
                if listId == "blocked_by" {
                    switch direction {
                    case "add":
                        self.peopleScene.removeBubbleById(uuid)
                        break
                    default:
                        break
                    }
                }
            }
        }
    }

    func freshPolygons() {

    }

    func onOverLimitEvent() {
        if FirebaseBankManager.sharedInstance.getUsage() < 500 {
            return
        }

        if UserManager.sharedInstance.isPremium() {
            return
        }

        // This method is called many times
        // For avoid increment cycles multiple times make a delay
        if shouldIncrementCycles {
            shouldIncrementCycles = false
            FirebasePeopleManager.sharedInstance.incrementNumberOfCycles()
            Utils.delay(2) {
                self.shouldIncrementCycles = true
            }
        }

    }

    func updateUsage(_ notification: Notification) {
        if let event = notification.object as? [String: Int] {
            if let balance = event["usage"] {
                balanceUsageLabel?.text = String(balance)
            }
        }
    }

    func showAds() {
        // banner ad stuff
        if !FirebaseIAPManager.sharedInstance.subcriptionsWereReceived {
            Utils.delay(2) {
                self.showAds()
            }
        } else {
            if StateManager.sharedInstance.shouldShowAds() {

            }
        }
    }

// MARK: - People Profile

    fileprivate func undoLastAction() {
        if showingBackScene {
            print("Not undoing in games")
        } else {
            SoundManager.sharedInstance.playSound(SoundManager.Sounds.swoosh2)
            peopleScene.undoLastAction(animated: true)
        }
    }

// MARK: - Bubble Delegate

    func tapOn(_ bubble: Bubble?) {
        print("TAP ON BUBBLE")
        if let bub = bubble as? PeopleBubble {

        }
    }

    func showProfile(_ uuid: String, image: UIImage?) {

        let profileStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.profile, bundle: nil)

        if let profileDetailVC = profileStoryboard.instantiateViewController(withIdentifier: ToucheApp.ViewControllerNames.profileDetailVC) as? ProfileDetailVC {

            FirebasePeopleManager.sharedInstance.getProfile(uuid) {
                [weak self] (profile) in
                if let profile = profile {
                    profileDetailVC.peopleVC = self
                    profileDetailVC.profile = profile
                    profileDetailVC.isMainUserProfile = false

                    if let image = image {
                        profileDetailVC.profilePic = image
                    }

                    //Utils.executeInMainThread({
                    //self.navigationController?.pushViewController(profileDetailVC, animated: true)
                    self?.navigationController?.present(profileDetailVC, animated: true, completion: nil)
                    //})
                }
            }

            // Consume
            let productId = FirebaseBankManager.ProductIds.ProfileSeen
            FirebaseBankManager.sharedInstance.consume(productId)

            // Log Profile Seen
            AnalyticsManager.sharedInstance.logEvent(productId, withTarget: uuid)

            // add to viewed lists
            FirebasePeopleManager.sharedInstance.view(uuid)
        }

    }

    func didAction(_ action: Action) {

        lastActionBubble = action.bubble

        if showingBackScene {
            print("Other Side of People Scene")
            print("Moved bubble to \(action.direction)")
        } else if let peopleBubble = action.bubble as? PeopleBubble {
            guard let userID = peopleBubble.user.userID else {
                return
            }
            //let timestamp = Utils.getTimestamp()
            //let value = [timestamp: userID]

            switch state {
            case State.Everyone, State.MyPolygons, State.MostViewed:

                switch action.direction {
                case .top:
                    FirebasePeopleManager.sharedInstance.hide(userID) { map in
                        self.counters.refreshCounters(map)
                    }
                    peopleScene.removeBubble(peopleBubble)
                    peopleScene.addActionCompleted(action)
                    SoundManager.sharedInstance.playSound(SoundManager.Sounds.boomerangFly)

                    // Log Hide Event
                    let eventId = FirebaseBankManager.ProductIds.Hide
                    AnalyticsManager.sharedInstance.logEvent(eventId, withTarget: userID)
                    break

                case .bottom:

                    FirebasePeopleManager.sharedInstance.like(userID) { map in
                        self.counters.refreshCounters(map)
                    }
                    peopleScene.removeBubble(peopleBubble)
                    peopleScene.addActionCompleted(action)

                    // Log Like Event
                    let eventId = FirebaseBankManager.ProductIds.Like
                    AnalyticsManager.sharedInstance.logEvent(eventId, withTarget: userID)
                    break

                default:
                    break
                }

                if self.peopleScene.count() <= 5 {
                    self.retrievePeopleFromLambda(state)
                }

            case State.Likes:
                switch action.direction {
                case .top:
                    FirebasePeopleManager.sharedInstance.unlike(userID)

                    // Log Unlike Event
                    let eventId = FirebaseBankManager.ProductIds.Unlike
                    AnalyticsManager.sharedInstance.logEvent(eventId, withTarget: userID)
                    break

                case .bottom:
                    peopleScene.moveBubble(action.bubble, toY: action.initialPosition.y, animated: false)

//                    let nc = navigationController
//                    FirebaseChatManager.sharedInstance.showConversationVCWithUser(userID, nc: nc, withBottomTopAnimation: true)
                    break

                default:
                    break
                }
                break

            case State.Hides:
                switch action.direction {
                case .top:
                    // blocks
                    FirebasePeopleManager.sharedInstance.unhide(userID)
                    FirebasePeopleManager.sharedInstance.block(userID)

                    // Log Block Event
                    let eventId = FirebaseBankManager.ProductIds.Block
                    AnalyticsManager.sharedInstance.logEvent(eventId, withTarget: userID)
                    break

                case .bottom:
                    // Unhide
                    FirebasePeopleManager.sharedInstance.unhide(userID)

                    // Log Unhide Event
                    let eventId = FirebaseBankManager.ProductIds.Unhide
                    AnalyticsManager.sharedInstance.logEvent(eventId, withTarget: userID)
                    break

                default:
                    break
                }
                break
            case State.Blocks:
                switch action.direction {
                case .bottom:
                    FirebasePeopleManager.sharedInstance.unblock(userID)
                    FirebasePeopleManager.sharedInstance.hide(userID) { map in

                    }

                    // Log Unblock Event
                    let eventId = FirebaseBankManager.ProductIds.Unblock
                    AnalyticsManager.sharedInstance.logEvent(eventId, withTarget: userID)
                    break

                default:
                    peopleScene.moveBubble(action.bubble, toY: action.initialPosition.y, animated: true)
                    break
                }
                break

            default:
                peopleScene.moveBubble(action.bubble, toY: action.initialPosition.y, animated: true)
                break
            }

        }
    }

// MARK: - GAME TEST

    fileprivate func showGame(_ toUUID: String) {
        guard let userUUID = UserManager.sharedInstance.toucheUUID else {
            return
        }

        let startGame = {
            [unowned self] in
            // Remove new game observer for avoiding two segues
            MessageBusManager.sharedInstance.removeObserver(self)
        }

        let randomTime = Double.random()
        Utils.delay(randomTime) {
            startGame()
        }
    }

}
