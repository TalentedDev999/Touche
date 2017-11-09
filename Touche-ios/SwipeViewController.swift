//
// Created by Lucas Maris on 3/23/17.
// Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SwiftyTimer
import Cupcake
import PKHUD
import SwiftLocation
import NVActivityIndicatorView
import LUAutocompleteView
import Cupcake
import CoreLocation
import Walker
import SwiftDate
import ISHPullUp
import ImageSlideshow
import TagListView

class SwipeViewController: ISHPullUpViewController, UITextFieldDelegate, ToucheProgressBarDelegate, UISearchBarDelegate, ISHPullUpStateDelegate, ISHPullUpSizingDelegate, TagListViewDelegate {

    public var swipeView: DMSwipeCardsView<JSON>!

    var slideshow: ImageSlideshow!

    private let autocompleteView: LUAutocompleteView = LUAutocompleteView()

    var textField = UITextField()

    var filters: [JSON] = []

    var isChromeHidden: Bool = false

    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))

    var searchResults: [JSON]!

    var playButton: UIButton!
    var backButton: UIButton!
    var nextButton: UIButton!
    var dislikeButton: UIButton!
    var likeButton: UIButton!
    var chatButton: UIButton!

    var playerButtons: CPKStackView!
    var counters: ToucheCounters!

    var spb: ToucheProgressBar!

    var handleView: ISHPullUpHandleView!

    private var firstAppearanceCompleted = false

    var lastCard: JSON? {
        willSet {
            if newValue == nil {
                self.backButton.isEnabled = false
            } else {
                self.backButton.isEnabled = true
            }
        }
    }

    var layout: CPKStackView?

    var mySearchBar: UISearchBar!

    var statusBar: ToucheStatusBar!

    var infoCard: ToucheInfoCard!

    var topBar: CPKStackView!

    var filterTags: TagListView!

    let seenOptions = [
            "Last Hour",
            "Today",
            "Last Week",
            "Last Month",
            "All Time"
    ]

    func dumpHides(_ notification: Notification) {
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(ToucheApp.activityData)
        FirebasePeopleManager.sharedInstance.dumpHides() { map in
            NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
            self.counters.refreshCounters(map)
            self.swipeView.clear()
            self.fetchProfiles()
        }
    }

    func viewLikes(_ notification: Notification) {

        self.filters.append(JSON(
                [
                    "type": "preset",
                    "name": "like"
                ]
        ))

        self.refreshFilterTags()
        self.swipeView.clear()
        self.fetchProfiles()
    }

    func openChat(_ notification: Notification) {
        if let uuid = notification.object as? String {
            self.hold()

            NVActivityIndicatorPresenter.sharedInstance.startAnimating(ToucheApp.activityData)
            TwilioChatManager.shared.initChat(withUuid: uuid) { csid in
                NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                let chat = Chat()
                chat.chatId = csid
                let conversationController = ConversationViewController(chat: chat)
                conversationController.channelSID = csid
                self.navigationController?.pushViewController(conversationController, animated: true)
            }
        }
    }

    func doLike(_ notification: Notification) {
        if let uuid = notification.object as? String {
            self.navigationController?.popViewController(animated: true)
            FirebasePeopleManager.sharedInstance.like(uuid, completion: { map in
                self.counters.refreshCounters(map)
                self.swipeView.swipeTopCardRight()
            })
        }
    }

    func doHide(_ notification: Notification) {
        if let uuid = notification.object as? String {
            self.navigationController?.popViewController(animated: true)
            FirebasePeopleManager.sharedInstance.hide(uuid, completion: { map in
                self.counters.refreshCounters(map)
                self.swipeView.swipeTopCardLeft()
            })
        }
    }


    func openProfile(_ notification: Notification) {
        if let profile = notification.object as? JSON {
            self.hold()
            self.navigationController?.pushViewController(ToucheProfileController(profile), animated: true)
        }
    }

    func showProfile(_ uuid: String, image: UIImage?) {
        let profileStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.profile, bundle: nil)

        if let profileDetailVC = profileStoryboard.instantiateViewController(withIdentifier: ToucheApp.ViewControllerNames.profileDetailVC) as? ProfileDetailVC {

            FirebasePeopleManager.sharedInstance.getProfile(uuid) {
                [weak self] (profile) in
                if let profile = profile {
                    //profileDetailVC.peopleVC = self
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
        }
    }

    func onLoginServicesReady() {

        self.checkBalanceAndFetch()
        self.counters.initialize()
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.swipeView.stop()
        return true
    }

    func checkBalanceAndFetch() {
        if self.counters.counterData["credits"] == 0 {

            // todo: display interstitial here

            self.fetchProfiles()

        } else {
            self.fetchProfiles()
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.start()
        textField.resignFirstResponder()
    }

//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        return true
//    }

    func viewControllerForPresentingModalView() -> UIViewController {
        return self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    private func commonInit() {

        self.contentViewController = UIViewController(nibName: nil, bundle: nil)
        self.bottomViewController = UIViewController(nibName: nil, bundle: nil)

        let roundedView = ISHPullUpRoundedView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        roundedView.backgroundColor = Color("#000,0.9")
        roundedView.cornerRadius = 20
        roundedView.strokeWidth = 0.0
        roundedView.shadowRadius = 0.5
        roundedView.shadowOpacity = 0.7

        self.bottomViewController!.view = roundedView

        self.handleView = ISHPullUpHandleView()
        self.handleView.strokeColor = ToucheApp.pinkColor

        self.stateDelegate = self
        self.sizingDelegate = self

    }

    private dynamic func handleTapInfoCard(gesture: UITapGestureRecognizer) {
        switch self.state {
        case ISHPullUpState.expanded:
            SoundManager.sharedInstance.playSound(SoundManager.Sounds.pauseMenuClose)
            self.start()
            break
        case ISHPullUpState.collapsed:
            SoundManager.sharedInstance.playSound(SoundManager.Sounds.chest)
            self.hold()
            break
        default:
            break
        }
        self.toggleState(animated: true)
    }

    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, didChangeTo state: ISHPullUpState) {
        handleView.setState(ISHPullUpHandleView.handleState(for: state), animated: firstAppearanceCompleted)
    }

    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, maximumHeightForBottomViewController bottomVC: UIViewController, maximumAvailableHeight: CGFloat) -> CGFloat {
        return self.contentViewController!.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height - 150
    }

    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, minimumHeightForBottomViewController bottomVC: UIViewController) -> CGFloat {
        return 50
    }

    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, targetHeightForBottomViewController bottomVC: UIViewController, fromCurrentHeight height: CGFloat) -> CGFloat {
        return height
    }

    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, update edgeInsets: UIEdgeInsets, forBottomViewController bottomVC: UIViewController) {
        if infoCard != nil && infoCard.scrollView != nil {
            self.infoCard.scrollView.contentInset = edgeInsets;
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true
        self.hold()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true
        self.start()
        firstAppearanceCompleted = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Utils.navigationControllerSetup(navigationController)

        Utils.setViewBackground(self.self.contentViewController!.view)

        self.edgesForExtendedLayout = UIRectEdge.init(rawValue: 0)
        self.automaticallyAdjustsScrollViewInsets = false

        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true

        mySearchBar = UISearchBar()
        mySearchBar.searchBarStyle = UISearchBarStyle.minimal
        mySearchBar.isTranslucent = false
        mySearchBar.barStyle = UIBarStyle.black
        mySearchBar.layer.shadowColor = UIColor.darkGray.cgColor
        mySearchBar.layer.shadowOpacity = 0.5
        mySearchBar.layer.masksToBounds = false
        mySearchBar.showsCancelButton = false
        mySearchBar.showsBookmarkButton = false

        let textFieldInsideUISearchBar = mySearchBar.value(forKey: "searchField") as? UITextField
        let textFieldInsideUISearchBarLabel = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideUISearchBarLabel?.font = ToucheApp.Fonts.montserratBig

        mySearchBar.placeholder = "Search"

        //mySearchBar.tintColor = UIColor.white
        //mySearchBar.barTintColor = UIColor.white
        mySearchBar.showsSearchResultsButton = false
        mySearchBar.delegate = self

        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.white

        textField = mySearchBar.subviews.flatMap {
            $0.subviews
        }.filter {
            $0 is UITextField
        }.first as! UITextField

        textField.font = ToucheApp.Fonts.montserratMedium

        //textField.delegate = self

        //self.navigationItem.titleView = mySearchBar


        setupProgressBar()
        setupCounters()
        //setupDropDowns()
        //setupSearch()
        setupFilterTags()
        setupLayout()
        setupSlideshow()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapInfoCard))
        self.infoCard.addGestureRecognizer(tapGesture)

        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.openChat), name: "openChat")
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.viewLikes), name: "viewLikes")
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.dumpHides), name: "dumpHides")
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.openProfile), name: "openProfile")
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.doLike), name: "doLike")
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.doHide), name: "doHide")

    }

    private func setupFilterTags() {
        self.filterTags = TagListView(frame: UIScreen.main.bounds)
        self.filterTags.autoresizingMask = .flexibleWidth
        self.filterTags.contentMode = .scaleAspectFit

        self.filterTags.textFont = Font("Montserrat-Light,13")
        self.filterTags.textColor = UIColor.white
        self.filterTags.alignment = .center
        self.filterTags.cornerRadius = 12.0
        self.filterTags.paddingX = 5.0
        self.filterTags.paddingY = 5.0
        self.filterTags.borderWidth = 0.0
        self.filterTags.shadowColor = UIColor.darkGray
        self.filterTags.enableRemoveButton = false
        self.filterTags.tagBackgroundColor = UIColor.black.withAlphaComponent(0.5)

        self.filterTags.delegate = self

        self.refreshFilterTags()

    }

    func refreshFilterTags() {

        self.filterTags.removeAllTags()

        let localityFilters = self.filters.filter {
            $0["type"].stringValue == "locality"
        }

        if localityFilters.count > 0 {
            let locFilter = localityFilters.first!["name"].stringValue
            self.filterTags.addTag("📍 \(locFilter)")
        } else {
            self.filterTags.addTag("📍 \("Nearby".translate())")
        }

        let presetFilters = self.filters.filter {
            $0["type"].stringValue == "preset"
        }

        for preset in presetFilters {
            if preset["name"] == "like" {
                self.filterTags.addTag("⭐️")
            }
        }

        if let seenFilter = FirebasePrefsManager.sharedInstance.pref("seenFilter") {
            self.filterTags.addTags(["🕐 \((seenFilter as! String).translate())"])
        } else {
            FirebasePrefsManager.sharedInstance.save("seenFilter", value: "All time")
            self.filterTags.addTags(["🕐 \("All time".translate())"])
        }
    }

    @objc func tagPressed(_ title: String, tagView: TagView, sender: TagListView) -> Void {

        self.hold()

        if title.contains("📍") {
            let idx = self.filters.map {
                $0["type"]
            }.index(of: "locality")

            if let idx = idx {
                self.filters.remove(at: idx)
                self.refreshFilterTags()
                self.swipeView.clear()
                self.fetchProfiles()
            } else {
                self.start()
            }
        }

        if title.contains("⭐️") {
            let idx = self.filters.map {
                $0["name"]
            }.index(of: "like")
            self.filters.remove(at: idx!)
            self.refreshFilterTags()
            self.swipeView.clear()
            self.fetchProfiles()
        }

        if title.contains("🕐") {



            let actionSheet = ActionSheet.title("Time Filter".translate())
                    .cancel("Cancel")

            if let seenFilter = FirebasePrefsManager.sharedInstance.pref("seenFilter") {
                let actions = seenOptions.filter {
                    $0 != seenFilter as! String
                }.map {
                    $0
                }

                for title in actions {
                    actionSheet.action(title.translate()) {
                        FirebasePrefsManager.sharedInstance.save("seenFilter", value: title)
                        self.refreshFilterTags()
                        self.swipeView.clear()
                        self.fetchProfiles()
                    }
                }

                actionSheet.show()
            }

        }
    }

    @objc func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) -> Void {

    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.textField.text = searchText
        self.hold()
    }

    private func setupDropDowns() {
        let titles = ["Apple", "Banana", "Kiwi", "Pear"]
        let dropDownViews = titles.map {
            Label.str($0).font(ToucheApp.Fonts.montserratBig).color("white")
        }

        let frame = CGRect(x: 0, y: 100, width: UIScreen.main.bounds.width, height: 50)

    }

    private func setupSlideshow() {
        slideshow = ImageSlideshow(frame: self.view.frame)

        slideshow.backgroundColor = UIColor.clear
        //slideshow.slideshowInterval = 5.0
        slideshow.pageControlPosition = PageControlPosition.insideScrollView
        slideshow.pageControl.currentPageIndicatorTintColor = ToucheApp.pinkColor
        slideshow.pageControl.pageIndicatorTintColor = UIColor.white
        slideshow.contentScaleMode = UIViewContentMode.scaleAspectFill

        // optional way to show activity indicator during image load (skipping the line will show no activity indicator)
        slideshow.activityIndicator = DefaultActivityIndicator()
        slideshow.currentPageChanged = { page in
            print("current page:", page)
        }


    }

    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.mySearchBar.text = ""
        self.contentViewController!.view.endEditing(true)
        self.hold()
        self.textField.resignFirstResponder()
        self.mySearchBar.resignFirstResponder()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.mySearchBar.text = ""
        self.textField.resignFirstResponder()
        self.mySearchBar.resignFirstResponder()
    }

    public func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        self.mySearchBar.text = ""
        self.textField.resignFirstResponder()
        self.mySearchBar.resignFirstResponder()
    }

    func setupProgressBar() {
        spb = ToucheProgressBar(frame: self.contentViewController!.view.frame)
        spb.delegate = self
    }

    private func setupSearch() {
        textField = UITextField(frame: self.contentViewController!.view.frame)

        textField.delegate = self

        textField.translatesAutoresizingMaskIntoConstraints = true
        textField.placeholder = ""
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = UITextBorderStyle.line
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.keyboardType = UIKeyboardType.default
        textField.returnKeyType = UIReturnKeyType.done
        textField.keyboardAppearance = UIKeyboardAppearance.dark
        textField.clearButtonMode = UITextFieldViewMode.whileEditing
        textField.leftViewMode = UITextFieldViewMode.always
        //textField.tintColor = UIColor.clear
        textField.backgroundColor = UIColor.darkGray
        textField.textColor = UIColor.white
        textField.alpha = 1.0
        textField.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        //textField.shadow(1.0)

        textField.isHidden = true

    }

    func setupCounters() {
        self.counters = ToucheCounters(frame: self.contentViewController!.view.frame)
        self.counters.initialize()
    }

    func setupLayout() {

        setupSwipeView()

        Styles("player").padding(5)
        Styles("action").padding(10).radius(-1).bg("#000,0.5")

        playButton = Button.styles("player").onClick({ _ in
            self.pause()
        }).img("player-play").pin(.wh(30, 30))

        dislikeButton = Button.styles("player").onClick({ _ in
            self.block()
        }).img("002-delete").pin(.wh(30, 30))

        nextButton = Button.styles("player").onClick({ _ in
            self.swipeView.swipeTopCardLeft()
        }).img("player-next").pin(.wh(30, 30))

        likeButton = Button.styles("player").onClick({ _ in
            self.swipeView.swipeTopCardRight()
        }).img("001-check").pin(.wh(30, 30))

        backButton = Button.styles("player").onClick({ _ in
            if let card = self.lastCard {
                SoundManager.sharedInstance.playSound(SoundManager.Sounds.pauseMenuCursor)
                self.resetProgressBar()
                self.swipeView.addCards([card], onTop: true)
                self.start()
                self.lastCard = nil
            }
        }).img("player-back").pin(.wh(30, 30))

        backButton.isEnabled = false

        playerButtons = HStack(
                "<-->",
                dislikeButton,
                20,
                backButton,
                20,
                playButton,
                20,
                nextButton,
                20,
                likeButton,
                "<-->"
        )

        self.statusBar = ToucheStatusBar(frame: self.contentViewController!.view.frame, distance: 200.0, lastSeen: "")
        self.statusBar.bg("#000,0.5").radius(-1)
                .pin(.wh(self.bottomViewController!.view.frame.width, 30))

        self.infoCard = ToucheInfoCard(frame: self.bottomViewController!.view.frame, handleView: handleView)
                .pin(.w(self.bottomViewController!.view.frame.width))

        self.infoCard.embedIn(self.bottomViewController!.view)

        self.topBar = HStack(
                0,
                swipeView.pin(.w(self.contentViewController!.view.frame.width)),
                0
        ).pin(.h(self.contentViewController!.view.frame.height))

        layout = VStack(
                0,
                topBar
        ).embedIn(self.contentViewController!.view, 0, 0, 0, 0)
                .pin(.wh(self.contentViewController!.view.frame.width, self.contentViewController!.view.frame.height))

        VStack(
                0,
                self.spb.pin(.h(5)),
                self.mySearchBar.bg("#000").shadow(0.5).pin(.h(30)),
                counters.shadow(0.5).pin(.wh(self.contentViewController!.view.frame.width, 40)),
                self.filterTags.pin(.wh(self.contentViewController!.view.frame.width, 20)),
                0
        ).embedIn(self.topBar, 0, 0, self.contentViewController!.view.frame.height - 200, 0)

        VStack(
                self.playerButtons.shadow(0.9).pin(.h(40)),
                "<-->"
        )
                .embedIn(self.topBar, self.contentViewController!.view.frame.height - 190, 0, 0, 0)

        //self.bottomViewController!.view.bringSubview(toFront: self.spb)

        self.contentViewController!.view.addSubview(autocompleteView)

        self.autocompleteView.textField = textField
        self.autocompleteView.dataSource = self
        self.autocompleteView.delegate = self
        self.autocompleteView.rowHeight = 45
        self.autocompleteView.maximumHeight = 225

        (autocompleteView as! UIView).alpha = 1.0

    }

    func fetchProfiles() {

        //self.swipeView.clear()

        self.hold()

        self.actuallyFetchProfiles()
//        PopupManager.sharedInstance.displayNextPopup() {
//        }
    }

    func actuallyFetchProfiles() {
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(ToucheApp.activityData)

        var currentLat = GeoManager.sharedInstance.currentLocation!.coordinate.latitude
        var currentLon = GeoManager.sharedInstance.currentLocation!.coordinate.longitude

        var preset = "nearby"

        let presetFilter = self.filters.filter {
            $0["type"].stringValue == "preset"
        }.first

        if let presetFilter = presetFilter {
            preset = presetFilter["name"].stringValue
        }

        let localityFilter = self.filters.filter {
            $0["type"].stringValue == "locality"
        }.first

        if let localityFilter = localityFilter {
            currentLat = localityFilter["lat"].doubleValue
            currentLon = localityFilter["lon"].doubleValue

            mySearchBar.placeholder = "Search"

            self.refreshFilterTags()
        }

        AWSLambdaManager.sharedInstance.nearbyProfiles(currentLat, lon: currentLon, preset: preset, completion: {
            (result, exception, error) in

            Utils.executeInMainThread {
                NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
            }

            if result != nil {
                let jsonResult = JSON(result!)
                let uuids = jsonResult[AWSLambdaManager.NearbyProfiles.Response.uuids].arrayValue
                let profiles = jsonResult[AWSLambdaManager.NearbyProfiles.Response.profiles].arrayValue
                print("uuids=\(uuids.count)")

                if uuids.count == 0 {

                    // we have hidden everyone already!
                    if self.counters.counterData["hide"] == 0 {

                        // downgrade the time search
                        if let seenFilter = FirebasePrefsManager.sharedInstance.pref("seenFilter") {
                            self.seenOptions.filter {
                                $0 == seenFilter as! String
                            }

                            if let idx = self.seenOptions.index(where: { $0 == seenFilter as! String }) {
                                let nextIdx = self.seenOptions.index(after: idx)
                                if nextIdx < self.seenOptions.count {
                                    let next = self.seenOptions[nextIdx]
                                    FirebasePrefsManager.sharedInstance.save("seenFilter", value: next)
                                    self.refreshFilterTags()
                                    self.swipeView.clear()
                                    self.fetchProfiles()
                                } else {
                                    // clear all filters
                                    self.filters.removeAll(keepingCapacity: false)
                                    self.refreshFilterTags()
                                    self.swipeView.clear()
                                    self.fetchProfiles()
                                }
                            }
                        }

                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name("dumpHides"), object: nil)
                    }

                } else {
                    self.swipeView.addCards(profiles, onTop: false)
                    self.start()
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

    func resetProgressBar() {
        self.spb.reset()
    }

    func progressBarFinished() {

        print("finished!!")

        if !PeopleManager.sharedInstance.hasInteractedRecently() {
            self.hold()

            // idle! the UI will just pause or display an ad!?

//            Alert.title("Alert").message("Are you still watching?").action("Yep!", {
//                PeopleManager.sharedInstance.lastTouch = Date()
//                self.swipeView.swipeTopCardLeft()
//            }).show()
        } else {
            self.swipeView.swipeTopCardLeft()
        }

    }

    private func setupSwipeView() {

        let viewGenerator: (JSON, CGRect) -> (UIView) = { (element: JSON, frame: CGRect) -> (UIView) in
            //let container = ToucheCard(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), profile: element)
            let container = ToucheCard(frame: frame, profile: element)

            container.layer.cornerRadius = 10
            container.layer.shadowRadius = 10
            container.layer.shadowOpacity = 1.0
            container.layer.shadowColor = UIColor.darkGray.cgColor
            container.layer.shadowOffset = CGSize(width: 0, height: 0)
            container.layer.shouldRasterize = true
            container.layer.rasterizationScale = UIScreen.main.scale

            return container
        }

        let overlayGenerator: (SwipeMode, CGRect) -> (UIView) = { (mode: SwipeMode, frame: CGRect) -> (UIView) in
            let label = UILabel()
            label.frame.size = CGSize(width: 100, height: 100)
            label.center = CGPoint(x: frame.width / 2, y: frame.height / 2)

            //label.layer.cornerRadius = label.frame.width / 2
            //label.backgroundColor = mode == .left ? UIColor.darkGray : UIColor.darkGray

            label.clipsToBounds = true
            label.text = mode == .left ? "❌" : "✅"
            label.font = UIFont.systemFont(ofSize: 40)

            label.textAlignment = .center
            return label
        }

        self.swipeView = DMSwipeCardsView<JSON>(frame: self.contentViewController!.view.frame,
                viewGenerator: viewGenerator,
                overlayGenerator: overlayGenerator)

        self.swipeView.delegate = self
    }

    private func block() {
        SoundManager.sharedInstance.playSound(SoundManager.Sounds.bombBlow)
        if let uuid = self.swipeView.uuid() {
            FirebasePeopleManager.sharedInstance.block(uuid, completion: {
                self.swipeView.swipeTopCardLeft()
            })
        } else {
            self.swipeView.swipeTopCardLeft()
        }
    }

    func pause() {
        if self.spb.isPaused {
            self.start()
        } else {
            self.hold()
        }
    }

    func adjustPlayButton() {
        if self.spb.isPaused {
            self.playButton.img("player-pause")
        } else {
            // always show the play button when playing
            self.playerButtons.isHidden = false
            self.playButton.img("player-play")
        }
    }

    func toggleChrome() {

        if self.isChromeHidden {
            // show chrome
            self.swipeView.run()
            self.swipeView.showChrome()
            self.isChromeHidden = false
        } else {
            // hide chrome
            self.hold()
            self.swipeView.hideChrome()
            self.isChromeHidden = true
        }

    }


    func start() {

        if let card: DMSwipeCard = self.swipeView.topCard() {

            Utils.executeInMainThread {

                Timer.every(100.milliseconds) { (timer: Timer) in
                    if card.toucheCard!.imageLoaded {

                        self.spb.isPaused = false
                        self.swipeView.isPaused = false
                        self.swipeView.start()

                        timer.invalidate()

                        card.alpha = 0.0
                        card.isHidden = false

                        //card.toucheCard!.backgroundImage.layer.
                        card.toucheCard!.backgroundImage.isHidden = false
                        card.toucheCard!.tagListView.isHidden = true
//                        card.toucheCard!.tagListView.alpha = 0.0
//                        card.toucheCard!.backgroundImage.alpha = 0.0
                        //card.toucheCard!.setupKeywords()
                        card.toucheCard!.backgroundImage.alpha = 1.0
                        card.toucheCard!.tagListView.alpha = 1.0
                        card.alpha = 1.0

                        self.adjustPlayButton()

                        if let profile = self.swipeView.profile() {
                            let pics = profile["pic_urls"].arrayValue
                            let sources = pics.map {
                                AlamofireSource(urlString: $0.stringValue)!
                            }
                            print(sources)
                            self.slideshow.setImageInputs(sources)

                            self.infoCard.refresh(profile)
                        }


//                        UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
//                            card.toucheCard!.tagListView.transform = CGAffineTransform(scaleX: CGFloat.random(1, 1.075), y: CGFloat.random(1, 1.075))
//                        }, completion: nil)

//                        UIView.animate(withDuration: 5, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
//                            card.toucheCard!.backgroundImage.transform = CGAffineTransform(scaleX: CGFloat.random(1, 1.075), y: CGFloat.random(1, 1.075))
//                            //card.toucheCard!.backgroundImage.transform = CGAffineTransform(rotationAngle: CGFloat.random(-0.025, 0.025))
//                        }, completion: nil)

                    } else {

                        print("loading image...")

                    }
                }

//                if self.spb.isPaused {
//                    self.spb.pause()
//                    self.swipeView.resumeLayer(layer: card.toucheCard!.backgroundImage.layer)
//                } else {
//
//                }

            }
        } else {
            self.swipeView.delegate?.reachedEndOfStack()
        }

    }

    func hold() {
        self.spb.isPaused = true
        self.swipeView.isPaused = true
        self.swipeView.hold()
        self.adjustPlayButton()
    }

}

extension SwipeViewController: DMSwipeCardsViewDelegate {
    func swipedLeft(_ object: Any) {
        SoundManager.sharedInstance.playSound(SoundManager.Sounds.boomerangFly)
        self.lastCard = object as! JSON
        let uuid = (object as! JSON)["uuid"].stringValue
        print("Swiped left: \(uuid)")
        self.resetProgressBar()
        FirebasePeopleManager.sharedInstance.hide(uuid, completion: { map in
            self.counters.refreshCounters(map)
            self.start()
        })
    }

    func swipedRight(_ object: Any) {
        SoundManager.sharedInstance.playSound(SoundManager.Sounds.pictoBoxSave)
        self.lastCard = object as! JSON
        let uuid = (object as! JSON)["uuid"].stringValue
        print("Swiped right: \(uuid)")
        self.resetProgressBar()
        FirebasePeopleManager.sharedInstance.like(uuid) { map in
            self.counters.refreshCounters(map)
            self.start()
        }
    }

    func cardTapped(_ object: Any) {
        let uuid = (object as! JSON)["uuid"].stringValue
        print("Tapped on: \(uuid)")

        self.hold()

        let fullScreenController = slideshow.presentFullScreenController(from: self)
        fullScreenController.slideshow.activityIndicator = DefaultActivityIndicator(style: .white, color: nil)


//        if let profile = self.swipeView.profile() {
//            NotificationCenter.default.post(name: NSNotification.Name("openProfile"), object: profile)
//        }
    }

    func cardUp(_ object: Any) {
        let uuid = (object as! JSON)["uuid"].stringValue
        print("Card up: \(uuid)")
        self.hold()
    }

    func cardDown(_ object: Any) {
        let uuid = (object as! JSON)["uuid"].stringValue
        print("Card down: \(uuid)")
        self.spb.isPaused = false
    }

    func reachedEndOfStack() {
        print("Reached end of stack")
        self.checkBalanceAndFetch()
    }

}

extension SwipeViewController: LUAutocompleteViewDataSource {
    func autocompleteView(_ autocompleteView: LUAutocompleteView, elementsFor text: String, completion: @escaping ([String]) -> Void) {

//        Utils.executeInMainThread {
//            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
//            self.textField.addSubview(activityIndicator)
//            activityIndicator.frame = CGRect(x: self.textField.bounds.origin.x, y: self.textField.bounds.origin.y, width: 50, height: self.textField.frame.height)
//            activityIndicator.startAnimating()
//        }

        if let prd = self.textField.text {

            AWSLambdaManager.sharedInstance.nearbyProfiles(GeoManager.sharedInstance.currentLocation!.coordinate.latitude, lon: GeoManager.sharedInstance.currentLocation!.coordinate.longitude, preset: "search", predicate: prd, completion: {
                (result, exception, error) in

                if result != nil {
                    let jsonResult = JSON(result!)
                    let uuids = jsonResult[AWSLambdaManager.NearbyProfiles.Response.uuids].arrayValue

                    self.searchResults = jsonResult[AWSLambdaManager.NearbyProfiles.Response.profiles].arrayValue

                    let results = self.searchResults.map {
                        "✈️\($0["name"].stringValue)"
                    }

                    Utils.executeInMainThread {
                        completion(results)
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


//        let elementsThatMatchInput = elements.filter {
//            $0.lowercased().contains(text.lowercased())
//        }
//        completion(elementsThatMatchInput)
    }
}

// MARK: - LUAutocompleteViewDelegate

extension SwipeViewController: LUAutocompleteViewDelegate {
    func autocompleteView(_ autocompleteView: LUAutocompleteView, didSelect text: String) {

        print(text + " was selected from autocomplete view")

        let entry = self.searchResults.filter {
            var t = text
            t.remove(at: t.startIndex) // remove the emoji
            return $0["name"].stringValue == t
        }.first

        //print(entry)

        self.swipeView.clear()

        // todo: store the keywords so that they are displayed under the search bar
        if let filter = entry {
            self.filters = [filter]
        }

        self.fetchProfiles()

        self.textField.text = ""
        self.textField.resignFirstResponder()
        self.mySearchBar.resignFirstResponder()
    }
}

