//
//  ProfileDetailVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 18/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import PopupDialog
import CoreLocation
import SwiftyJSON
import Alamofire
import AlamofireImage
import SDCAlertView
import Emoji
import Mapbox
import PKHUD
import ImageViewer


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
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ProfileDetailVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, MGLMapViewDelegate {

    // MARK: - Variables

    var peopleVC: PeopleVC?

    //var chatVC: ChatConversationVC?

    var isMainUserProfile = true
    fileprivate var isFirstLoad = true

    var map: MGLMapView!


    var profile: ProfileModel?
    @IBOutlet weak var profileHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var profileWidthConstraint: NSLayoutConstraint!

    fileprivate var photoModel = [PhotoDataModel]() {
        didSet {
            if photoModel.count > 0 {
                Utils.executeInMainThread({ [weak self] in
                    self?.collectionViewHeightConstraint.constant = 70
                })
            }

            if let userUUID = profile?.uuid {
                for photo in photoModel {
                    let imageName = photo.picUuid
                    let defaultImage = UIImage(named: ToucheApp.Assets.defaultImageName)

                    let size = 300
                    let url = PhotoManager.sharedInstance.getPhotoURLFromName(imageName, userUuid: userUUID, size: size, centerFace: false, flip: false)

                    photo.imageView.af_setImage(withURL: url,
                            placeholderImage: defaultImage,
                            imageTransition: .crossDissolve(0.2),
                            completion: { response in
                                if let image: UIImage = response.result.value {
                                    Utils.executeInMainThread { [weak self] in
                                        self?.collectionView.reloadData()
                                    }
                                }
                            })

                    let sizeHQ = Int(Utils.screenHeight)
                    let urlHQ = PhotoManager.sharedInstance.getPhotoURLFromName(imageName, userUuid: userUUID, size: sizeHQ, centerFace: false, flip: false)

                    photo.imageViewHQ.af_setImage(withURL: urlHQ,
                            placeholderImage: photo.imageView.image,
                            imageTransition: .crossDissolve(0.2),
                            completion: { response in
                                if let image: UIImage = response.result.value {
                                    photo.imageViewHQ.image = image
                                    photo.imageViewHQAvailable = true
                                }
                            })


                    imageViews.append(photo.imageViewHQ)
                }
            }

            Utils.executeInMainThread { [weak self] in
                self?.collectionView.reloadData()
            }
        }
    }

    var profilePic: UIImage?

    var imageViews: [UIImageView] = []

    fileprivate var picHeight: CGFloat = 70

    fileprivate var selectedPicIndexPath: IndexPath?

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var closeButton: UIButton!

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!

    @IBOutlet weak var publicButtonsStackView: UIStackView!
    @IBOutlet weak var privateButtonsStackView: UIStackView!
    @IBOutlet weak var actionButtonsStackView: UIStackView!

    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var showKeywordButton: UIButton!
    @IBOutlet weak var showImagesButton: UIButton!

    @IBOutlet weak var seenLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    fileprivate var locationTagView: OTagListView?
    fileprivate var meTagView: OTagListView?
    fileprivate var youTagView: OTagListView?
    fileprivate var likeTagView: OTagListView?
    fileprivate var dislikeTagView: OTagListView?

    fileprivate var me = [String]() {
        didSet {
            meTagView = OTagListView(frame: CGRect(x: 0, y: 0, width: Utils.screenWidth - 54, height: 40))

            if let tagView = meTagView {
                tagView.isUserInteractionEnabled = true
                tagView.isScrollEnabled = false
                tagView.tag = 0

                for key in me {
                    tagView.addTag("#" + key,
                            target: self,
                            tapAction: #selector(ProfileDetailVC.tapOnKeywordHashtag(_:)),
                            longPressAction: #selector(ProfileDetailVC.longPressOnKeywordHashtag(_:)),
                            backgroundColor: UIColor.clear,
                            textColor: UIColor.white,
                            tag: 0)
                }
                tagViewToShow.append(("💪", tagView))
            }
        }
    }
    fileprivate var you = [String]() {
        didSet {
            youTagView = OTagListView(frame: CGRect(x: 0, y: 0, width: Utils.screenWidth - 48, height: 40))
            if let tagView = youTagView {
                tagView.isUserInteractionEnabled = true
                tagView.isScrollEnabled = false
                tagView.tag = 1

                for key in you {
                    tagView.addTag("#" + key,
                            target: self,
                            tapAction: #selector(ProfileDetailVC.tapOnKeywordHashtag(_:)),
                            longPressAction: #selector(ProfileDetailVC.longPressOnKeywordHashtag(_:)),
                            backgroundColor: UIColor.clear,
                            textColor: UIColor.white,
                            tag: 1)
                }
                tagViewToShow.append(("😍", tagView))
            }
        }
    }

    fileprivate var like = [String]() {
        didSet {
            likeTagView = OTagListView(frame: CGRect(x: 0, y: 0, width: Utils.screenWidth - 48, height: 40))
            if let tagView = likeTagView {
                tagView.isUserInteractionEnabled = true
                tagView.isScrollEnabled = false
                tagView.tag = 2

                for key in like {
                    tagView.addTag("#" + key,
                            target: self,
                            tapAction: #selector(ProfileDetailVC.tapOnKeywordHashtag(_:)),
                            longPressAction: #selector(ProfileDetailVC.longPressOnKeywordHashtag(_:)),
                            backgroundColor: UIColor.clear,
                            textColor: UIColor.white,
                            tag: 2)
                }
                tagViewToShow.append(("👍", tagView))
            }
        }
    }

    fileprivate var dislike = [String]() {
        didSet {
            dislikeTagView = OTagListView(frame: CGRect(x: 0, y: 0, width: Utils.screenWidth - 48, height: 40))
            if let tagView = dislikeTagView {
                tagView.isUserInteractionEnabled = true
                tagView.isScrollEnabled = false
                tagView.tag = 3

                for key in dislike {
                    tagView.addTag("#" + key,
                            target: self,
                            tapAction: #selector(ProfileDetailVC.tapOnKeywordHashtag(_:)),
                            longPressAction: #selector(ProfileDetailVC.longPressOnKeywordHashtag(_:)),
                            backgroundColor: UIColor.clear,
                            textColor: UIColor.white,
                            tag: 3)
                }
                tagViewToShow.append(("👎", tagView))
            }
        }
    }

    fileprivate var tagViewToShow = Array<(String, OTagListView)>() {
        didSet {
            Utils.executeInMainThread { [weak self] in
                self?.tableView.isHidden = false
                self?.tableView.reloadData()
            }
        }
    }
    fileprivate var keywordImage = [UIImage]()

    fileprivate var isAlreadyInLikes = false {
        didSet {
            if isAlreadyInLikes {
                likeButton.setImage(nil, for: UIControlState())
                likeButton.setTitle("⭐️", for: UIControlState())
            } else {
                likeButton.setTitle(nil, for: UIControlState())
                likeButton.setFAIcon(icon: .FAStar, forState: UIControlState())
                likeButton.setFATitleColor(color: UIColor.darkGray, forState: UIControlState())
            }
        }
    }

    fileprivate var polygonModel: [PolygonModel] = [] {
        didSet {
            locationTagView = OTagListView(frame: CGRect(x: 0, y: 0, width: Utils.screenWidth - 48, height: 40))

            if let tagView = locationTagView {
                tagView.isUserInteractionEnabled = true
                tagView.isScrollEnabled = false
                tagView.tag = 0

                for polygon in polygonModel {
                    tagView.addTag(polygon.name,
                            target: self,
                            tapAction: #selector(ProfileDetailVC.tapOnKeywordHashtag(_:)),
                            longPressAction: #selector(ProfileDetailVC.longPressOnKeywordHashtag(_:)),
                            backgroundColor: UIColor.clear,
                            textColor: UIColor.white,
                            tag: 10)
                }

                tagViewToShow.insert(("🗺", tagView), at: 0)
            }
        }
    }

    let keywordTypeLabels: [String] = ["💪", "😍", "👍", "👎"]


    // MARK: - Lifecycle Methods

    fileprivate var hisLocation: CLLocation!
    fileprivate var hisUuid: String!

    fileprivate var annotationImageMe: MGLAnnotationImage!
    fileprivate var annotationImageHim: MGLAnnotationImage!

//    fileprivate func buildActionMenu() {
//        if menu == nil {
//            let menuEntries: [EliminationMenu.Item] = [
//                    EliminationMenu.Item(value: "noop", title: ":white_circle:".emojiUnescapedString),
//                    EliminationMenu.Item(value: "block_user", title: ":bomb:".emojiUnescapedString)
//            ]
//
//            menu = EliminationMenu.createMenu(withItems: menuEntries, inView: self.view, aligned: .bottomRight, margin: CGPoint(x: 16, y: 8)) {
//                (item) in
//                switch item.value as! String {
//                case "block_user":
//
//                    PopupManager.sharedInstance.simplePopup(
//                            "💣 Block this user?".translate(),
//                            message: "All your conversations will be deleted and this user will not be able to see you anymore".translate(),
//                            okButtonText: "Yes".translate(),
//                            cancelButtonText: "No".translate(),
//                            okCompletion: {
//                                if let userUUID = self.profile?.uuid {
//                                    SoundManager.sharedInstance.playSound(SoundManager.Sounds.bombBlow)
//                                    FirebasePeopleManager.sharedInstance.block(userUUID)
//                                    self.presentingViewController?.dismiss(animated: true, completion: nil)
//
//                                    if let peopleVC = self.peopleVC {
//                                        peopleVC.removeCurrentProfileDetailBubble()
//                                    }
//
//                                    if let chatVC = self.chatVC {
//                                        chatVC.tapOnBack()
//                                        MessageBusManager.sharedInstance.postNotificationName(EventNames.People.refresh)
//                                    }
//
//                                    // it should also delete the conversation you had with this person
//                                    FirebaseChatManager.sharedInstance.deleteConversationFor(userUUID, completion: {
//                                        print("conversation deleted")
//                                    })
//
//                                }
//                            },
//                            cancelCompletion: {
//                            }
//                    )
//                    break
//                default:
//                    break
//                }
//            }
//
//            menu.eliminate = false
//
//            menu.font = UIFont.boldSystemFont(ofSize: 35)
//            menu.color = UIColor.white
//
//
//            menu.setup()
//        }
//
//
//    }

    fileprivate func registerForListChangeNotifications() {
        let listChangeSelector = #selector(ProfileDetailVC.onListChange)
        let listChangeEvent = EventNames.List.didChange
        MessageBusManager.sharedInstance.addObserver(self, selector: listChangeSelector, name: listChangeEvent)
    }

    func onListChange(_ notification: Notification) {
        if let event = notification.object as? [String: String] {
            if let listId = event["listId"], let direction = event["direction"], let uuid = event["uuid"] {
                // if you were blocked by someone while looking at the person's profile
                if listId == "blocked_by" {
                    switch direction {
                    case "add":
                        self.tapOnBack()
                        break
                    default:
                        break
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.navigationItemSetup(navigationItem)

        collectionViewHeightConstraint.constant = 0

        let font = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: 17)
        distanceLabel.font = font
        seenLabel.font = font
        distanceLabel.isUserInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileDetailVC.tapOnDistanceLabel))
        distanceLabel.addGestureRecognizer(tapGestureRecognizer)


        if isMainUserProfile {
            getMainUserProfile()
        } else {

            SoundManager.sharedInstance.playSound(SoundManager.Sounds.textboxOpen)

            initialSetup()
            registerForListChangeNotifications()

            if let profile = profile {
                initLeftNavigationItem()

                isAlreadyInLikes = FirebasePeopleManager.sharedInstance.isUserAlreadyInLikes(profile.uuid)

                if let seen = profile.seen {
                    let timeInterval = TimeInterval(seen / 1000)
                    let date = Date(timeIntervalSince1970: timeInterval)

                    seenLabel.text = "⏳\n" + Utils.getTimeElapsedFromDate(date, toDate: Date())
                } else {
                    seenLabel.text = nil
                }

                distanceLabel.isHidden = true
            }
        }

        let profileTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileDetailVC.tapOnProfilePic))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(profileTapGestureRecognizer)
    }

    override func viewDidLayoutSubviews() {
        profileImageView.circle()
        chatButton.circle()
        likeButton.circle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isMainUserProfile && !isFirstLoad {
            resetKeywords()
            getMainUserProfile()
        } else {
            isFirstLoad = false
        }
    }


    // MARK: - Helper Methods

    fileprivate func getMainUserProfile() {
        if let uuid = UserManager.sharedInstance.toucheUUID {
            FirebasePeopleManager.sharedInstance.getProfile(uuid, completion: { [weak self] (profileModel) in
                if let profile = profileModel {
                    self?.profile = profile
                    self?.initialSetup()
                }
            })
        }
    }

    fileprivate func resetKeywords() {
        me.removeAll()
        you.removeAll()
        like.removeAll()
        dislike.removeAll()
        keywordImage.removeAll()
        tagViewToShow.removeAll()

        meTagView = nil
        youTagView = nil
        likeTagView = nil
        dislikeTagView = nil
        locationTagView = nil
    }

    fileprivate func initialSetup() {
        Utils.executeInMainThread { [weak self] in
            self?.updateUI()
            self?.initImageViewer()
        }
        getUserLocation()
        getKeywords()
        getUserPics()
        getUserPolygonData()
        loadMyPic()
        loadHisPic()
    }

    func tapOnProfilePic() {

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.textboxBegin)

        Utils.executeInMainThread { [weak self] in
            self?.showGalleryImageViewer(0)
        }

        // Consume
        let productId = FirebaseBankManager.ProductIds.ZoomPhoto
        FirebaseBankManager.sharedInstance.consume(productId)

        // Log
        if let userUUID = profile?.uuid {
            AnalyticsManager.sharedInstance.logEvent(productId, withTarget: userUUID)
        } else {
            AnalyticsManager.sharedInstance.logEvent(productId)
        }
    }

    fileprivate func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clear
    }

    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100

        tableView.isHidden = true
    }

    fileprivate func updateUI() {
        updateProfileImage()
        updateProfileBackgroundImage()
        updateButtons()

        let profileSize = Utils.screenWidth / 2
        profileWidthConstraint.constant = profileSize
        profileHeightConstraint.constant = profileSize

        setupCollectionView()
        setupTableView()
    }

    fileprivate func initImageViewer() {
        if let profile = profile, let picUuid = profile.pic {
            let fullProfileImageViewer = UIImageView()
            let size = Int(Utils.screenHeight)
            let url = PhotoManager.sharedInstance.getPhotoURLFromName(picUuid, userUuid: profile.uuid, size: size, centerFace: false)
            fullProfileImageViewer.af_setImage(withURL: url,
                    placeholderImage: profileImageView.image)

            imageViews = [fullProfileImageViewer]
        } else {
            imageViews = [profileImageView]
        }
    }

    fileprivate func updateProfileImage() {
        let defaultImage = UIImage(named: ToucheApp.Assets.defaultImageName)

        if profilePic == nil {
            if let profile = profile, let picUuid = profile.pic {
                let url = PhotoManager.sharedInstance.getPhotoURLFromName(picUuid, userUuid: profile.uuid)
                profileImageView.af_setImage(withURL: url,
                        placeholderImage: defaultImage)

            } else {
                profileImageView.image = defaultImage
            }
        } else {
            profileImageView.image = profilePic
        }
    }

    fileprivate func updateProfileBackgroundImage() {
        backgroundImageView.clipsToBounds = true
        backgroundImageView.image = profileImageView.image

        Utils.addBlurView(backgroundImageView, style: .dark)
    }

    fileprivate func updateButtons() {
        publicButtonsStackView.isHidden = true
        privateButtonsStackView.isHidden = true
        actionButtonsStackView.isHidden = true
        closeButton.isHidden = true
        seenLabel.isHidden = true


        if isMainUserProfile {
            privateButtonsStackView.isHidden = false
            actionButtonsStackView.isHidden = true
        } else {
            //buildActionMenu()
            actionButtonsStackView.isHidden = false
            publicButtonsStackView.isHidden = false
            closeButton.isHidden = false
            seenLabel.isHidden = false
        }
    }

    fileprivate func initLeftNavigationItem() {
        let leftButtonImage = UIImage(named: ToucheApp.Assets.backButtonItem)
        let leftButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(ProfileDetailVC.tapOnBack))
        leftButtonItem.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = leftButtonItem
    }

    fileprivate func getKeywords() {
        if let profile = profile {
            FirebaseKeywordManager.sharedInstance.getKeywordsForUser(profile.uuid) { [weak self] (snapshot) in
                if let snapshotDict = snapshot?.value as? [String: AnyObject] {
                    var meKeys = [String]()
                    var youKeys = [String]()
                    var likeKeys = [String]()
                    var dislikeKeys = [String]()

                    if let meKeywords = snapshotDict[FirebaseKeywordManager.Database.Profile.KeywordType.me] as? [String: AnyObject] {
                        for key in meKeywords {
                            meKeys.append(key.0)
                        }
                    }
                    if let youKeywords = snapshotDict[FirebaseKeywordManager.Database.Profile.KeywordType.you] as? [String: AnyObject] {
                        for key in youKeywords {
                            youKeys.append(key.0)
                        }
                    }
                    if let likeKeywords = snapshotDict[FirebaseKeywordManager.Database.Profile.KeywordType.like] as? [String: AnyObject] {
                        for key in likeKeywords {
                            likeKeys.append(key.0)
                        }
                    }
                    if let dislikeKeywords = snapshotDict[FirebaseKeywordManager.Database.Profile.KeywordType.dislike] as? [String: AnyObject] {
                        for key in dislikeKeywords {
                            dislikeKeys.append(key.0)
                        }
                    }

                    if meKeys.count > 0 {
                        let image = UIImage(named: ToucheApp.Assets.Keyword.me)
                        if image != nil {
                            self?.keywordImage.append(image!)
                        }
                        self?.me = meKeys
                    }
                    if youKeys.count > 0 {
                        let image = UIImage(named: ToucheApp.Assets.Keyword.you)
                        if image != nil {
                            self?.keywordImage.append(image!)
                        }
                        self?.you = youKeys
                    }
                    if likeKeys.count > 0 {
                        let image = UIImage(named: ToucheApp.Assets.Keyword.like)
                        if image != nil {
                            self?.keywordImage.append(image!)
                        }
                        self?.like = likeKeys
                    }
                    if dislikeKeys.count > 0 {
                        let image = UIImage(named: ToucheApp.Assets.Keyword.dislike)
                        if image != nil {
                            self?.keywordImage.append(image!)
                        }
                        self?.dislike = dislikeKeys
                    }
                } else {
                    Utils.executeInMainThread({
                        self?.tableView.isHidden = false
                    })
                }
            }
        }
    }

    fileprivate func getUserPics() {
        if let profile = profile {
            FirebasePhotoManager.sharedInstance.getPicsFromUser(profile.uuid, completion: { [weak self] (snapshot) in
                if let picDict = snapshot.value as? [String: AnyObject] {
                    var tempPhotoModel = [PhotoDataModel]()

                    for pic in picDict {
                        let photo = PhotoDataModel()

                        photo.picUuid = pic.0
                        photo.downloadComplete = true

                        if let snapshotDict = pic.1 as? [String: AnyObject] {
                            if let moderationDate = snapshotDict[FirebasePhotoManager.Database.Pic.moderationDate] as? Int {
                                photo.moderationDate = moderationDate
                            }
                            if let moderated = snapshotDict[FirebasePhotoManager.Database.Pic.moderated] as? Bool {
                                photo.moderated = moderated
                            }
                            if let adult = snapshotDict[FirebasePhotoManager.Database.Pic.adult] as? Bool {
                                photo.adult = adult
                            }
                            if let hash = snapshotDict[FirebasePhotoManager.Database.Pic.hash] as? String {
                                photo.imageHash = hash
                            }
                            if let type = snapshotDict[FirebasePhotoManager.Database.Pic.type] as? String {
                                photo.type = type
                            }
                        }

                        if photo.type != "chat" {
                            if self?.isMainUserProfile == true && pic.0 != profile.pic {
                                tempPhotoModel.append(photo)
                            } else if photo.moderationDate != nil && photo.moderated == true && photo.adult == false && pic.0 != profile.pic {
                                tempPhotoModel.append(photo)
                            }
                        }
                    }

                    tempPhotoModel = tempPhotoModel.sorted(by: { $0.moderationDate > $1.moderationDate })

                    self?.photoModel = tempPhotoModel
                }
            })
        }
    }

    func getLocationForUser(_ userUUID: String, completion: @escaping (CLLocation?, Error?) -> Void) {
        // call get profiles lambda
        AWSLambdaManager.sharedInstance.getProfiles([userUUID]) { result, exception, error in
            //print(result)
            print(error)

            if result != nil {
                let jsonResult = JSON(result!)
                let latitude = jsonResult["data"][userUUID]["geoloc"]["lat"].doubleValue
                let longitude = jsonResult["data"][userUUID]["geoloc"]["lon"].doubleValue

                //print("latitude=\(latitude)")
                //print("longitude=\(longitude)")

                self.hisLocation = CLLocation(latitude: latitude, longitude: longitude)
                self.hisUuid = userUUID

                completion(self.hisLocation, error)
            }

            completion(nil, nil)
        }
    }

    fileprivate func getUserLocation() {
        if !isMainUserProfile, let profile = profile {
            getLocationForUser(profile.uuid) { [weak self] (location, error) in
                if let error = error {
                    print(error)
                }
                if let location = location, let currentLocation = CoreLocationManager.sharedInstance.currentLocation {
                    var distance = currentLocation.distance(from: location)
                    var distanceUnit = "m"

                    if distance >= 1000 {
                        distance = distance / 1000
                        distanceUnit = "km"
                    }

                    let bearing = CoreLocationManager.sharedInstance.getBearingBetweenTwoPoints(currentLocation, point2: location)

                    let distanceString = "📍\(bearing)\n" + String(format: "%.0f ", distance) + distanceUnit

                    Utils.executeInMainThread({
                        self?.distanceLabel.text = distanceString
                        self?.distanceLabel.isHidden = false
                    })
                }
            }
        }
    }

    fileprivate func getUserPolygonData() {
        if let uuid = profile?.uuid {
//            FirebasePeopleManager.sharedInstance.getPolygonDataForUser(uuid, completion: { [weak self] (snapshot) in
//                if let snapshotDict = snapshot.value as? [[String: AnyObject]] {
//                    var auxModel = [PolygonModel]()
//
//                    for item in snapshotDict {
//                        if let id = item["id"] as? String,
//                           let adminLevel = item["adminLevel"] as? Int,
//                           let name = item["name"] as? String {
//
//                            let newPolygon = PolygonModel(id: id, name: name, adminLevel: adminLevel, connect(:, <#T##UnsafePointer<sockaddr>##Swift.UnsafePointer<Darwin.sockaddr>#>, <#T##socklen_t##Darwin.socklen_t#>))
//
//                            auxModel.append(newPolygon)
//                        }
//                    }
//
//                    auxModel = auxModel.sort({ $0.adminLevel < $1.adminLevel })
//
//                    self?.polygonModel = auxModel
//                }
//            })
        }
    }

    fileprivate func showKeywordPopup(_ keyword: String, tag: Int) {

        let title = keywordTypeLabels[tag] + " " + keyword

        let popup = PopupDialog(title: title, message: nil)
        popup.buttonAlignment = .horizontal

        let cancelButton = CancelButton(title: "⬅️") {
            SoundManager.sharedInstance.playSound(SoundManager.Sounds.boomerangFly)
            print("Cancel keyword popup.")
        }
        let deleteButton = DefaultButton(title: "🗑") {
            if let type = FirebaseKeywordManager.sharedInstance.getTypeFromTag(tag) {
                let key = keyword.replacingOccurrences(of: "#", with: "")
                FirebaseKeywordManager.sharedInstance.removeKeyword(key, type: type)

                self.resetKeywords()
                self.getUserPolygonData()
                self.getKeywords()

                print("Delete keyword: \(keyword) Type: \(type)")
                SoundManager.sharedInstance.playSound(SoundManager.Sounds.pictoBoxErase)
            }
        }

        let dialogAppearance = PopupDialogDefaultView.appearance()
        dialogAppearance.backgroundColor = UIColor.white
        dialogAppearance.titleFont = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: 20)!
        dialogAppearance.titleColor = UIColor.black
        dialogAppearance.titleTextAlignment = .center

        popup.addButtons([cancelButton, deleteButton])

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.textboxQuestion)

        present(popup, animated: true)
    }


    // MARK: - Selectors

    @IBAction func closeButton(_ sender: UIButton) {
        tapOnBack()
    }

    func tapOnBack() {
        SoundManager.sharedInstance.playSound(SoundManager.Sounds.boomerangFly)
        if !isMainUserProfile {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func tapOnChat(_ sender: UIButton) {
        if let profile = profile, let nav = self.peopleVC?.navigationController {

            let uuid = profile.uuid

            FirebasePeopleManager.sharedInstance.isPrimaryPicSetted { (result) in
                if (result) {
                    SoundManager.sharedInstance.playSound(SoundManager.Sounds.pauseMenuEquip)
                    self.presentingViewController?.dismiss(animated: true, completion: {
                        FirebaseChatManager.sharedInstance.showConversationVCWithUser(uuid, nc: nav)
                    })
                } else {
                    SoundManager.sharedInstance.playSound(SoundManager.Sounds.error)
                }
            }


            return
        }

//        if let _ = chatVC?.navigationController {
//            presentingViewController?.dismiss(animated: true, completion: nil)
//        }
    }

    @IBAction func tapOnLike(_ sender: UIButton) {
        if !isMainUserProfile {
            if let profile = profile {

                FirebasePeopleManager.sharedInstance.isPrimaryPicSetted { (result) in
                    if (result) {
                        // Change like status
                        if self.isAlreadyInLikes {
                            SoundManager.sharedInstance.playSound(SoundManager.Sounds.pauseMenuQuit)
                            FirebasePeopleManager.sharedInstance.unlike(profile.uuid)
                            self.isAlreadyInLikes = false
                        } else {
                            SoundManager.sharedInstance.playSound(SoundManager.Sounds.pigGrunt)
                            FirebasePeopleManager.sharedInstance.like(profile.uuid) { map in

                            }
                            self.isAlreadyInLikes = true
                        }

                        // If opened from PeopleVC we have to change bubble status
                        if let peopleVC = self.peopleVC {
                            // Like state do not matter because it is observing and detects like status change
                            if peopleVC.state != PeopleVC.State.Likes {
                                if self.isAlreadyInLikes {
                                    //peopleVC.removeCurrentProfileDetailBubble()

                                    switch peopleVC.state {
                                    case PeopleVC.State.Blocks:
                                        FirebasePeopleManager.sharedInstance.unblock(profile.uuid)
                                    case PeopleVC.State.Hides:
                                        FirebasePeopleManager.sharedInstance.unhide(profile.uuid)
                                    default:
                                        break
                                    }
                                } else {
                                    peopleVC.addCurrentProfileDetailBubble()

                                    switch peopleVC.state {
                                    case PeopleVC.State.Blocks:
                                        FirebasePeopleManager.sharedInstance.block(profile.uuid)
                                    case PeopleVC.State.Hides:
                                        FirebasePeopleManager.sharedInstance.hide(profile.uuid) { map in

                                        }
                                    default:
                                        break
                                    }
                                }
                            }
                        }
                    } else {
                        SoundManager.sharedInstance.playSound(SoundManager.Sounds.error)
                    }
                }


            }
        }
    }

    @IBAction func tapOnKeyword(_ sender: UIButton) {
        let profileStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.profile, bundle: nil)

        if let keywordsVC = profileStoryboard.instantiateViewController(withIdentifier: ToucheApp.ViewControllerNames.profileKeywordsVC) as? ProfileKeywordsVC {
            navigationController?.pushViewController(keywordsVC, animated: true)
        }
    }

    @IBAction func tapOnShowImages(_ sender: UIButton) {
        let photosStoryboard = UIStoryboard(name: ToucheApp.StoryboardsNames.photos, bundle: nil)

        if let photosCollectionVC = photosStoryboard.instantiateViewController(withIdentifier: ToucheApp.ViewControllerNames.photosCollectionVC) as? PhotosCollectionVC {
            photosCollectionVC.showBackButton = true
            navigationController?.pushViewController(photosCollectionVC, animated: true)
        }
    }

    func tapOnDistanceLabel(_ sender: UITapGestureRecognizer) {
        print("tap on distance")
        showMap()
    }

    func showMap() {
        map = MGLMapView(frame: view.bounds)

        map.setCenter(self.hisLocation.coordinate, animated: true)

        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        map.styleURL = MGLStyle.darkStyleURL(withVersion: 9)
        //map.userTrackingMode = .Follow
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        map.isScrollEnabled = false
        map.isZoomEnabled = false

        let popupView = MapPopup(frame: self.view.frame, contentView: map)
        //popupView.heightPopPourcent = 50.0
        //popupView.widthPopPourcent = 50.0

        /// Add to subview
        self.view.addSubview(popupView)
        /// Open Popup
        popupView.start()

        self.map.delegate = self

        let hello1 = MGLPointAnnotation()
        hello1.coordinate = self.hisLocation.coordinate
        hello1.title = self.hisUuid

        let hello2 = MGLPointAnnotation()
        hello2.coordinate = CoreLocationManager.sharedInstance.currentLocation!.coordinate
        hello2.title = UserManager.sharedInstance.toucheUUID!

        self.map.addAnnotation(hello1)
        self.map.addAnnotation(hello2)

        self.map.showAnnotations([hello1, hello2], edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
    }

    func loadHisPic() {
        if let profile = profile {
            let userUuid = profile.uuid
            PhotoManager.sharedInstance.getAvatarImageFor(userUuid, placeholderImage: UIImage(named: ToucheApp.Assets.defaultImageName)!.circle!) { (imageHim) in
                if let image = imageHim {
                    if let circle = image.dot {
                        self.annotationImageHim = MGLAnnotationImage(image: circle, reuseIdentifier: userUuid)
                    }
                }
            }
        }
    }


    func loadMyPic() {
        if let meUuid = UserManager.sharedInstance.toucheUUID {
            PhotoManager.sharedInstance.getAvatarImageFor(meUuid, placeholderImage: UIImage(named: ToucheApp.Assets.defaultImageName)!.circle!) { (imageMe) in
                if let image = imageMe {
                    if let circle = image.dot {
                        self.annotationImageMe = MGLAnnotationImage(image: circle, reuseIdentifier: meUuid)
                    }
                }
            }
        }
    }



    open func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let title = annotation.title {
            if self.hisUuid == title {
                return annotationImageHim
            }
        }
        return annotationImageMe
    }

    open func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return false
    }


    func tapOnKeywordHashtag(_ sender: UIGestureRecognizer) {

        // todo: launch keyword search

        let label = (sender.view as! UILabel)
        print("Tag: \(label.tag) -> Key \(label.text!)")
    }

    func longPressOnKeywordHashtag(_ sender: UIGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began && isMainUserProfile {
            if let label = sender.view as? UILabel, let keyword = label.text {
                if label.tag < 4 {
                    showKeywordPopup(keyword, tag: label.tag)
                    print("Tag: \(label.tag) -> Long Press Key \(keyword)")
                }
            }
        }
    }


    // MARK: - TableView Delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return tagViewToShow.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let name = KeywordCell.name

        let cell = tableView.dequeueReusableCell(withIdentifier: name, for: indexPath)
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none

        if let keywordCell = cell as? KeywordCell {
            if tagViewToShow.count > indexPath.row {
                //&& keywordImage.count > indexPath.row {

                for view in keywordCell.tagListScrollView.subviews {
                    view.removeFromSuperview()
                }

                //cell.typeImage.image = keywordImage[indexPath.row]
                keywordCell.typeImage.alpha = 0

                let tagList = tagViewToShow[indexPath.row].1

                keywordCell.typeLabel.text = tagViewToShow[indexPath.row].0

                keywordCell.tagListHeightConstraint.constant = 30

                if tagList.contentSize.height > 30 {
                    let height = tagList.contentSize.height
                    tagList.frame = CGRect(x: 0, y: 0, width: Utils.screenWidth - 54, height: height)
                    keywordCell.tagListHeightConstraint.constant = height
                }

                let topOffset = CGPoint(x: 0, y: -tagList.contentInset.top + 6)
                tagList.setContentOffset(topOffset, animated: false)

                keywordCell.tagListScrollView.addSubview(tagList)

                keywordCell.sizeToFit()
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    // MARK: - CollectionView Delegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoModel.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let name = PhotosCollectionCell.name
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)

        if let photoCell = cell as? PhotosCollectionCell {
            photoCell.lockButton.isUserInteractionEnabled = false
            photoCell.lockButton.isHidden = true
            photoCell.imageView.alpha = 1

            let photo = photoModel[indexPath.item]

            if photo.moderated == false {
                photoCell.imageView.alpha = 0.4
                photoCell.lockButton.isHidden = false
            }

            photoCell.imageView.image = photo.imageView.image

            cell.setNeedsLayout()
        }

        return cell
    }

    //Use for size
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {

        return CGSize(width: picHeight, height: picHeight)
    }

    //Use for interspacing
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1.0
    }

    func collectionView(_ collectionView: UICollectionView, layout
    collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {

        return 1.0
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedPicIndexPath = indexPath

        Utils.executeInMainThread { [weak self] in
            self?.showGalleryImageViewer(indexPath.item + 1)
        }
    }


    // MARK: - Image Viewer Delegate

    fileprivate func showGalleryImageViewer(_ index: Int) {
        let frame = CGRect(x: 0, y: 0, width: 200, height: 24)
        let headerView = CounterView(frame: frame, currentIndex: index, count: imageViews.count)

//        let galleryViewController = GalleryViewController(startIndex: index, itemsDatasource: self, displacedViewsDatasource: self, configuration: galleryConfiguration())
//
//        galleryViewController.headerView = headerView
//
//        galleryViewController.launchedCompletion = {
//            print("LAUNCHED")
//        }
//        galleryViewController.closedCompletion = {
//            print("CLOSED")
//        }
//        galleryViewController.swipedToDismissCompletion = {
//            print("SWIPE-DISMISSED")
//            SoundManager.sharedInstance.playSound(SoundManager.Sounds.boomerangFly)
//        }
//
//        galleryViewController.landedPageAtIndexCompletion = { index in
//            print("LANDED AT INDEX: \(index)")
//            headerView.currentIndex = index
//            SoundManager.sharedInstance.playSound(SoundManager.Sounds.textboxNext)
//        }

//        self.presentImageGallery(galleryViewController)
    }


    func itemCount() -> Int {

        return imageViews.count
    }

    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView? {
        var displacement: DisplaceableView?
        if let index = selectedPicIndexPath, let cell = collectionView.cellForItem(at: index) as? PhotosCollectionCell {
            displacement = cell.imageView
            selectedPicIndexPath = nil
        } else {
            displacement = profileImageView
        }

        return displacement
    }

    func provideGalleryItem(_ index: Int) -> GalleryItem {
        let image = imageViews[index].image ?? UIImage(named: ToucheApp.Assets.defaultImageName)!

        return GalleryItem.image {
            $0(image)
        }
    }

    func galleryConfiguration() -> GalleryConfiguration {

        let closeButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 55, height: 55)))
        closeButton.setFAIcon(icon: .FAClose, forState: UIControlState())

        return [
                GalleryConfigurationItem.pagingMode(.carousel),
                GalleryConfigurationItem.presentationStyle(.displacement),
                GalleryConfigurationItem.hideDecorationViewsOnLaunch(true),

                GalleryConfigurationItem.thumbnailsButtonMode(.none),
                GalleryConfigurationItem.closeButtonMode(.custom(closeButton)),

                GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
                GalleryConfigurationItem.overlayColorOpacity(1),
                GalleryConfigurationItem.overlayBlurOpacity(1),
                GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.light),

                //GalleryConfigurationItem.maximumZoolScale(8),
                GalleryConfigurationItem.swipeToDismissThresholdVelocity(500),

                GalleryConfigurationItem.doubleTapToZoomDuration(0.15),

                GalleryConfigurationItem.blurPresentDuration(0.5),
                GalleryConfigurationItem.blurPresentDelay(0),
                GalleryConfigurationItem.colorPresentDuration(0.25),
                GalleryConfigurationItem.colorPresentDelay(0),

                GalleryConfigurationItem.blurDismissDuration(0.1),
                GalleryConfigurationItem.blurDismissDelay(0.4),
                GalleryConfigurationItem.colorDismissDuration(0.45),
                GalleryConfigurationItem.colorDismissDelay(0),

                GalleryConfigurationItem.itemFadeDuration(0.3),
                GalleryConfigurationItem.decorationViewsFadeDuration(0.15),
                GalleryConfigurationItem.rotationDuration(0.15),

                GalleryConfigurationItem.displacementDuration(0.55),
                GalleryConfigurationItem.reverseDisplacementDuration(0.25),
                GalleryConfigurationItem.displacementTransitionStyle(.springBounce(0.7)),
                GalleryConfigurationItem.displacementTimingCurve(.linear),

                GalleryConfigurationItem.statusBarHidden(true),
                GalleryConfigurationItem.displacementKeepOriginalInPlace(false),
                GalleryConfigurationItem.displacementInsetMargin(50)
        ]
    }

}
