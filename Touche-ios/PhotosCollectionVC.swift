//
//  PhotosCollectionVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import Photos
import Fusuma
import MBProgressHUD
import SwiftMessages
import PopupDialog
import AWSS3

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <<T:Comparable>(lhs: T?, rhs: T?) -> Bool {
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
fileprivate func ><T:Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


class PhotosCollectionVC: UICollectionViewController, UIGestureRecognizerDelegate, FusumaDelegate {
    func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode) {
        
    }


    // MARK: - Initial Variables
    fileprivate var hud: MBProgressHUD?

    fileprivate let numberOfImagesPerRow = 3
    fileprivate let distanceBetweenCells = 1

    fileprivate var photoModel = [PhotoDataModel]() {
        didSet {
            if primaryPic == nil {
                setPrimaryPicIfAvailable()
            }
            photoModel = photoModel.sorted(by: { $0.moderationDate > $1.moderationDate })
            Utils.executeInMainThread { [weak self] in
                self?.collectionView?.reloadData()
            }
        }
    }

    var primaryPic: String? {
        didSet {
            Utils.executeInMainThread { [weak self] in
                self?.collectionView?.reloadData()
            }
        }
    }

    fileprivate var uploadInProgress = false
    fileprivate var picsUploaded = [String]()
    fileprivate var numberOfPicsUploading = 0 {
        didSet {
            if numberOfPicsUploading == 0 {
                uploadInProgress = false
            }
        }
    }

    var showBackButton = false

    var shouldReload = false

    var initialTiemestamp: Int?

    // MARK: - Life Cycle Methods

    func close() {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hud = ProgressHudManager.blockCustomView(view)

        Utils.navigationControllerSetup(navigationController)
        navigationController?.isNavigationBarHidden = false

        //Utils.navigationItemSetup(navigationItem)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))

        Utils.setCollectionViewBackground(collectionView)

        initialTiemestamp = Int(Utils.getTimestampMilis())

        if showBackButton {
            initLeftNavigationItem()
        }

        initCollectionView()

        getFirebasePixs()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        initialTiemestamp = Int(Utils.getTimestampMilis())

        if shouldReload {
            photoModel.removeAll()
            getFirebasePixs()
        } else {
            shouldReload = true
        }

        FirebaseChatManager.sharedInstance.currentNavigationController = navigationController
    }


    // MARK: - Helper Methods

    fileprivate func initLeftNavigationItem() {
        let leftButtonImage = UIImage(named: ToucheApp.Assets.backButtonItem)
        let leftButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(PhotosCollectionVC.tapOnBack))
        leftButtonItem.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = leftButtonItem
    }

    fileprivate func initCollectionView() {
        collectionView?.alwaysBounceVertical = true

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(PhotosCollectionVC.handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delaysTouchesBegan = true
        longPressGesture.delegate = self
        collectionView?.addGestureRecognizer(longPressGesture)
    }

    fileprivate func getFirebasePixs() {
        if let userUuid = UserManager.sharedInstance.toucheUUID {
            FirebasePeopleManager.sharedInstance.getProfilePic(userUuid) { [weak self] (pic) in
                if pic != nil {
                    self?.primaryPic = pic!
                    Utils.executeInMainThread {
                        self?.collectionView?.reloadData()
                    }
                } else {
                    self?.primaryPic = nil
                }
            }

            FirebasePhotoManager.sharedInstance.getPicsFromUser(userUuid, completion: { [weak self] (snapshot) in
                if let snapshotDict = snapshot.value as? [String: AnyObject] {
                    var tempPhotoModel = [PhotoDataModel]()

                    for pic in snapshotDict {
                        let photo = PhotoDataModel()
                        photo.picUuid = pic.0
                        photo.downloadComplete = false

                        if let picDict = pic.1 as? [String: AnyObject] {
                            if let moderationDate = picDict[FirebasePhotoManager.Database.Pic.moderationDate] as? Int {
                                photo.moderationDate = moderationDate
                            }
                            if let moderated = picDict[FirebasePhotoManager.Database.Pic.moderated] as? Bool {
                                photo.moderated = moderated
                            }
                            if let adult = picDict[FirebasePhotoManager.Database.Pic.adult] as? Bool {
                                photo.adult = adult
                            }
                            if let hash = picDict[FirebasePhotoManager.Database.Pic.hash] as? String {
                                photo.imageHash = hash
                            }
                            if let type = picDict[FirebasePhotoManager.Database.Pic.type] as? String {
                                photo.type = type
                            }

                            if photo.type != "chat" {
                                if photo.moderated == false || photo.adult == true {
                                    photo.showLock = true
                                }

                                let defaultImage = UIImage(named: ToucheApp.Assets.defaultImageName)
                                var placeholder: UIImage?

                                placeholder = defaultImage
                                self?.setImageForPhoto(photo, placeholder: placeholder)

                                tempPhotoModel.append(photo)
                            }
                        }
                    }
                    self?.photoModel = tempPhotoModel

                    // if there are no pics, then open image picker
//                    print("tempPhotoModel.count=\(tempPhotoModel.count)")
//
//                    if let uploading = self?.uploadInProgress {
//                        if tempPhotoModel.count == 0 && !uploading {
//                            self?.showImagePicker()
//                        }
//                    }

                }
                self?.observePics()
                if let sself = self, let hud = sself.hud {
                    ProgressHudManager.unblockCustomView(sself.view, hud: hud)
                }
            })
        }
    }

    fileprivate func observePics() {
        if let userUuid = UserManager.sharedInstance.toucheUUID {
            FirebasePhotoManager.sharedInstance.observePicAddedForUser(userUuid, completion: { [weak self] (snapshot) in
                if let snapshotDict = snapshot.value as? [String: AnyObject] {

                    print(snapshotDict)

                    if self?.picsUploaded.contains(snapshot.key) == false {
                        return
                    }

                    if let index = self?.picsUploaded.index(of: snapshot.key) {
                        self?.picsUploaded.remove(at: index)
                    }

                    let photo = PhotoDataModel()
                    photo.picUuid = snapshot.key
                    photo.downloadComplete = false

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

                    if photo.type != "chat" {
                        Utils.executeInMainThread({ [weak self] in
                            var alreadyShowing = false
                            var originalPic: UIImage?

                            if self?.photoModel != nil {
                                for (index, element) in self!.photoModel.enumerated() {
                                    // Already exists, do not download the pic
                                    if element.picUuid == photo.picUuid {
                                        originalPic = self!.photoModel[index].imageView.image

                                        self?.photoModel[index] = photo
                                        self?.photoModel[index].showLock = false

                                        var approved = true
                                        if photo.moderated == false {
                                            approved = false
                                            photo.showLock = true
                                        }

                                        // Check moderation date before showing moderation alert
                                        if let initialTiemestamp = self?.initialTiemestamp {
                                            if photo.moderationDate > initialTiemestamp {
                                                self?.showModerationAlert(approved)

                                                if approved {
                                                    PhotoManager.sharedInstance.pixelate = false
                                                    self?.collectionView?.reloadData()
                                                }
                                            }
                                        }

                                        self?.initialTiemestamp = Int(Utils.getTimestampMilis())

                                        alreadyShowing = true
                                    }
                                }

                                if photo.moderated == false || photo.adult == true {
                                    photo.showLock = true
                                }

                                let defaultImage = UIImage(named: ToucheApp.Assets.defaultImageName)
                                var placeholder: UIImage?

                                if !alreadyShowing {
                                    placeholder = defaultImage
                                    self?.photoModel.append(photo)
                                } else {
                                    placeholder = originalPic
                                }

                                self?.setImageForPhoto(photo, placeholder: placeholder)
                            }
                        })
                    }
                }
            })

            FirebasePhotoManager.sharedInstance.observePicRemovedForUser(userUuid, completion: { [weak self] (snapshot) in
                if let index = self?.getIndexForPhoto(snapshot.key) {
                    self?.photoModel.remove(at: index)

                    if self?.primaryPic == snapshot.key {
                        self?.setPrimaryPicIfAvailable()
                    }

                    Utils.executeInMainThread { [weak self] in
                        self?.collectionView?.reloadData()
                    }
                }
            })
        }
    }

    fileprivate func getIndexForPhoto(_ picUuid: String) -> Int? {
        var tempPhoto: PhotoDataModel?

        for photo in photoModel {
            if photo.picUuid == picUuid {
                tempPhoto = photo
                break
            }
        }

        if let photo = tempPhoto {
            return photoModel.index(of: photo)
        } else {
            return nil
        }
    }

    fileprivate func setImageForCell(_ cell: PhotosCollectionCell, picUuid: String) {
        let url = PhotoManager.sharedInstance.getPhotoURLFromName(picUuid, userUuid: UserManager.sharedInstance.toucheUUID!, size: 300, centerFace: false, flip: false)
        cell.imageView.af_setImage(withURL: url)
    }

    fileprivate func setImageForPhoto(_ photo: PhotoDataModel, placeholder: UIImage?) {
        let url = PhotoManager.sharedInstance.getPhotoURLFromName(photo.picUuid, userUuid: UserManager.sharedInstance.toucheUUID!, size: 300, centerFace: false, flip: false)

        photo.imageView.af_setImage(withURL: url,
                placeholderImage: placeholder,
                completion: { response in
                    if let image: UIImage = response.result.value {
                        Utils.executeInMainThread({
                            photo.downloadComplete = true
                            photo.imageView.image = image
                            self.collectionView?.reloadData()
                        })
                    }
                })
    }

    fileprivate func showImagePicker() {
//        let imagePickerController = ImagePickerController()
//        imagePickerController.delegate = self
//        Configuration.collapseCollectionViewWhileShot = false
//
//        presentViewController(imagePickerController, animated: true, completion: nil)

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.getItem)

        let fusuma = FusumaViewController()
        fusuma.delegate = self
        fusuma.hasVideo = false // If you want to let the users allow to use video.
        self.present(fusuma, animated: true, completion: nil)
    }

//    // Return the image which is selected from camera roll or is taken via the camera.
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.getHeart)

        print("Image selected")
        uploadInProgress = true

        var lastName = ""

        let newPhoto = PhotoDataModel()
        newPhoto.imageView.image = image
        newPhoto.picUuid = generateName()

        while lastName == newPhoto.picUuid {
            newPhoto.picUuid = generateName()
        }
        lastName = newPhoto.picUuid

        // Temp timestamp to see uploading pics first in collection
        newPhoto.moderationDate = Int(Utils.getTimestampMilis())

        newPhoto.showHourGlass = true

        photoModel.append(newPhoto)

        if let index = photoModel.index(of: newPhoto) {
            numberOfPicsUploading += 1

            uploadPhotoForIndex(index)
        }

        presentedViewController?.dismiss(animated: true, completion: nil)
    }

    // Return the image but called after is dismissed.
    func fusumaDismissedWithImage(_ image: UIImage) {

        print("Called just after FusumaViewController is dismissed.")
    }

    func fusumaVideoCompleted(withFileURL fileURL: URL) {

        print("Called just after a video has been selected.")
    }

    // When camera roll is not authorized, this method is called.
    func fusumaCameraRollUnauthorized() {

        print("Camera roll unauthorized")

        let alert = UIAlertController(title: "Access Requested", message: "Saving image needs to access your photo album", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) -> Void in

            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(url)
            }

        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in

        }))

        self.present(alert, animated: true, completion: nil)

    }

    func fusumaImageSelected(_ image: UIImage, source: FusumaMode, metaData: ImageMetadata) {
    }

    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {
    }

    func fusumaClosed() {
    }

    func fusumaWillClosed() {
    }


    fileprivate func generateName() -> String {
        let uuid = UUID().uuidString
        return uuid
    }

    fileprivate func showModerationAlert(_ approved: Bool) {
        let notificationView = MessageView.viewFromNib(layout: .StatusLine)
        notificationView.configureDropShadow()

        print("pic is approved=\(approved)")

        if approved {
            let moderationSuccessEvent = EventNames.ModerationPicture.success
            MessageBusManager.sharedInstance.postNotificationName(moderationSuccessEvent)

            notificationView.configureTheme(.success)
            notificationView.configureContent(body: "📷 👍")
            SoundManager.sharedInstance.playSound(SoundManager.Sounds.pictoBoxSave)
        } else {
            let moderationFailEvent = EventNames.ModerationPicture.fail
            MessageBusManager.sharedInstance.postNotificationName(moderationFailEvent)

            notificationView.configureTheme(.error)
            notificationView.configureContent(body: "📷 👎")
            SoundManager.sharedInstance.playSound(SoundManager.Sounds.bombBlow)
        }

        Utils.executeInMainThread {
            SwiftMessages.show(view: notificationView)
        }
    }

    fileprivate func showImagePopover(_ image: UIImage, picUUID: String) {
        let photosStoryboardName = ToucheApp.StoryboardsNames.photos
        let photosStoryboard = UIStoryboard(name: photosStoryboardName, bundle: nil)
        let photoDeletePopoverName = ToucheApp.PopoverNames.photoDelete
        let photoDeletePopoverVC = photosStoryboard.instantiateViewController(withIdentifier: photoDeletePopoverName)

        let popover = PopupDialog(viewController: photoDeletePopoverVC, gestureDismissal: false)

        if let popoverVC = photoDeletePopoverVC as? PhotoDeletePopoverVC {
            popoverVC.photoCollectionVC = self
            popoverVC.popoverDialog = popover
            popoverVC.imageView.image = image
            popoverVC.imageUUID = picUUID

            present(popover, animated: true, completion: nil)
        }
    }

    fileprivate func setPrimaryPicIfAvailable() {
        if let user = UserManager.sharedInstance.toucheUUID {
            for photo in photoModel {
                if photo.moderationDate != nil && photo.moderated == true && photo.adult == false {
                    primaryPic = photo.picUuid
                    FirebasePeopleManager.sharedInstance.setPrimaryPic(user, primaryPic: photo.picUuid)
                }
            }
        }
    }

    fileprivate func disableLock(_ cell: PhotosCollectionCell) {
        UIView.performWithoutAnimation {
            cell.lockButton.isHidden = true
            cell.imageView.alpha = 1
        }
    }

    fileprivate func setPhotoCellLock(_ cell: PhotosCollectionCell) {
        if cell.lockButton.isHidden {
            UIView.performWithoutAnimation({
                cell.imageView.alpha = 0.4
                cell.lockButton.titleLabel?.text = "🔒"
                cell.lockButton.isHidden = false
            })
        }
    }

    fileprivate func setPhotoCellHourGlass(_ cell: PhotosCollectionCell) {
        if cell.lockButton.isHidden {
            UIView.performWithoutAnimation({
                cell.imageView.alpha = 0.4
                cell.lockButton.titleLabel?.text = "⌛️"
                cell.lockButton.isHidden = false
            })
        }
    }

    fileprivate func reloadCellWithPicUUID(_ picUUID: String) {
        if let cells = collectionView?.visibleCells as? [PhotosCollectionCell] {
            for cell in cells {
                if cell.picUUID == picUUID {
                    if let index = collectionView?.indexPath(for: cell) {
                        collectionView?.reloadItems(at: [index])
                    }
                }
            }
        }
    }

    // MARK: - Selectors

    func tapOnBack() {
        SoundManager.sharedInstance.playSound(SoundManager.Sounds.boomerangFly)
        navigationController?.popViewController(animated: true)
    }

    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == UIGestureRecognizerState.began {
            let p = gestureReconizer.location(in: self.collectionView)
            let indexPath = self.collectionView?.indexPathForItem(at: p)

            if let index = indexPath, index.item > 0 {
                if let cell = self.collectionView?.cellForItem(at: index) as? PhotosCollectionCell,
                   let image = cell.imageView.image, let picUUID = cell.picUUID {

                    if cell.showHourGlass {
                        return
                    }

                    showImagePopover(image, picUUID: picUUID)
                    print("\(index.item) -> \(picUUID)")
                }
            }
        }
    }



    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoModel.count + 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellName = PhotosCollectionCell.name

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath)

        let index = indexPath.item

        if let photoCell = cell as? PhotosCollectionCell {
            photoCell.lockButton.isUserInteractionEnabled = false
            photoCell.lockButton.isHidden = true
            photoCell.imageView.alpha = 1

            if index == 0 {
                photoCell.backgroundColor = UIColor.clear
                photoCell.imageView.contentMode = .center
                //let image = UIImage(icon: .FAUpload, size: CGSize(width: 50, height: 50), textColor: UIColor.white, backgroundColor: UIColor.clearColor())
                let image = ":calling:".emojiUnescapedString.image(50, height: 60)
                photoCell.imageView.image = image
            } else {
                let photo = photoModel[index - 1]

                if photo.picUuid == primaryPic {
                    photoCell.borderPrimary()
                }

                photoCell.imageView.contentMode = .scaleAspectFill
                photoCell.imageView.image = photo.imageView.image
                photoCell.picUUID = photo.picUuid
                photoCell.showLock = photo.showLock
                photoCell.showHourGlass = photo.showHourGlass

                if photo.downloadComplete {
                    if photo.showLock {
                        setPhotoCellLock(photoCell)
                    } else {
                        disableLock(photoCell)
                    }
                } else {
                    setPhotoCellHourGlass(photoCell)
                }
            }
        }

        cell.setNeedsLayout()

        return cell
    }

    //Use for size
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {

        let columns = CGFloat(numberOfImagesPerRow)
        let spacing = CGFloat(distanceBetweenCells * numberOfImagesPerRow - 1) / columns

        let size = (Utils.screenWidth / columns) - spacing

        return CGSize(width: size, height: size)
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

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            shouldReload = false
            showImagePicker()
        } else {
            if let user = UserManager.sharedInstance.toucheUUID {
                let pic = photoModel[indexPath.item - 1]

                // Pic already primary or not downloaded
                if pic.picUuid == primaryPic || pic.showHourGlass == true {
                    return
                }

                // Check moderation status before setting primary
                if pic.moderationDate != nil && pic.moderated == true && pic.adult == false {
                    FirebasePeopleManager.sharedInstance.setPrimaryPic(user, primaryPic: pic.picUuid)
                    primaryPic = pic.picUuid

                    print("Primary Pic changed: \(pic.picUuid)")
                }
            }
        }
    }


    // MARK: - Upload Handler

    fileprivate func uploadPhotoForIndex(_ index: Int) {
        // create a local image that we can use to upload to s3
        if let image = photoModel[index].imageView.image, let path = photoModel[index].path, let jpgImageData: Data = UIImageJPEGRepresentation(image, 0.5) {
            let result = (try? jpgImageData.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil

            if result {
                // create a local file url
                let url: URL = URL(fileURLWithPath: path)

                // Setup the S3 upload request manager
                let uploadRequest = AWSS3TransferManagerUploadRequest()!
                uploadRequest.bucket = ToucheApp.amazonBucket
                uploadRequest.key = UserManager.sharedInstance.toucheUUID! + "/" + photoModel[index].picUuid
                uploadRequest.contentType = ToucheApp.amazonContentType
                uploadRequest.body = url;

                // create the transfer manager, the credentials are already set up in the app delegate
                let transferManager: AWSS3TransferManager = AWSS3TransferManager.default()

                // start the upload
                transferManager.upload(uploadRequest).continueWith(block: { [weak self]
                task -> AnyObject in

                    // once the uploadmanager finishes check if there were any errors
                    if (task.error != nil) {
                        print("Image Save Error. Number: \(uploadRequest.key)")
                        print(task.error)
                    } else {
                        if let key = uploadRequest.key,
                           let range = key.range(of: "/") {

                            var picUUID = key.substring(from: range.lowerBound)

                            // removing starting slash
                            picUUID.remove(at: picUUID.startIndex)

                            if let index = self?.photoModel.index(where: { $0.picUuid == picUUID }),
                               let photo = self?.photoModel[index] {

                                if photo.picUuid == picUUID {
                                    self?.picsUploaded.append(picUUID)

                                    photo.downloadComplete = false
                                    photo.uploadComplete = true
                                    photo.showHourGlass = true
                                    photo.showLock = false

                                    self?.numberOfPicsUploading -= 1

                                    self?.photoModel[index].imageView.alpha = 0.4

                                    Utils.executeInMainThread {
                                        self?.collectionView?.reloadData()
                                    }

                                    print("PIC UPLOAD COMPLETE")
                                }
                            }
                        }
                    }

                    return "finished" as AnyObject
                })


            }
        }
    }

}
