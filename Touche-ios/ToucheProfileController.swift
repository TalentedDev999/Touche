//
// Created by Lucas Maris on 7/11/17.
// Copyright (c) 2017 toucheapp. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import ImageSlideshow
import NVActivityIndicatorView
import ISHPullUp
import Cupcake
import TagListView
import AlamofireImage
import MapKit

class ToucheProfileController: ISHPullUpViewController, ISHPullUpStateDelegate, TagListViewDelegate {

    var uuid: String!
    var profile: JSON!

    private var firstAppearanceCompleted = false

    let alamofireSource = [AlamofireSource(urlString: "https://images.unsplash.com/photo-1432679963831-2dab49187847?w=1080")!, AlamofireSource(urlString: "https://images.unsplash.com/photo-1447746249824-4be4e1b76d66?w=1080")!, AlamofireSource(urlString: "https://images.unsplash.com/photo-1463595373836-6e0b0a8ee322?w=1080")!]

    var slideshow: ImageSlideshow!

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    var handleView: ISHPullUpHandleView!

    var visibleTopBar: CPKStackView!

    init(_ profile: JSON) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)

        self.contentViewController = UIViewController(nibName: nil, bundle: nil)
        self.bottomViewController = UIViewController(nibName: nil, bundle: nil)

        let roundedView = ISHPullUpRoundedView(frame: UIScreen.main.bounds)
        roundedView.backgroundColor = ToucheApp.pinkColor
        roundedView.cornerRadius = 20
        self.bottomViewController!.view = roundedView


//        let roundedView = ISHPullUpRoundedView(frame: UIScreen.main.bounds)
//        roundedView.cornerRadius = 20
//        self.bottomViewController!.view = roundedView

//        self.contentDelegate = self
        //self.sizingDelegate = self
        self.stateDelegate = self

    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Utils.setViewBackground(self.view)

        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true

        firstAppearanceCompleted = true

        //self.navigationController?.navigationBar.backgroundColor = UIColor.clear

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        SoundManager.sharedInstance.playSound(SoundManager.Sounds.textboxOpen)

        self.uuid = self.profile["uuid"].stringValue
        let picUuid = self.profile["pic"].stringValue
        let pics = self.profile["pic_urls"].arrayValue

        //print(pics)

        self.setupLayout(pics)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        visibleTopBar.addGestureRecognizer(tapGesture)

        //self.setBottomHeight(100, animated: false)


//        NVActivityIndicatorPresenter.sharedInstance.startAnimating(ActivityData(type: .ballPulseSync, color: Color("#D40265")))
//
//        AWSLambdaManager.sharedInstance.getProfiles([uuid]) { result, exception, error in
//
//            NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
//
//            if result != nil {
//                let jsonResult = JSON(result!)
//                self.profile = jsonResult["data"][self.uuid]
//
//            }
//        }


    }

    private dynamic func handleTapGesture(gesture: UITapGestureRecognizer) {
        self.toggleState(animated: true)
    }

    func didTap() {
        let fullScreenController = slideshow.presentFullScreenController(from: self)
        // set the activity indicator for full screen controller (skipping the line will show no activity indicator)
        fullScreenController.slideshow.activityIndicator = DefaultActivityIndicator(style: .white, color: nil)
    }

    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, didChangeTo state: ISHPullUpState) {
        handleView.setState(ISHPullUpHandleView.handleState(for: state), animated: firstAppearanceCompleted)
    }

//    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, maximumHeightForBottomViewController bottomVC: UIViewController, maximumAvailableHeight: CGFloat) -> CGFloat {
//        return self.contentViewController!.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
//    }
//
//    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, minimumHeightForBottomViewController bottomVC: UIViewController) -> CGFloat {
//        return 100
//    }
//
//    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, targetHeightForBottomViewController bottomVC: UIViewController, fromCurrentHeight height: CGFloat) -> CGFloat {
//        return height
//    }
//
//    func pullUpViewController(_ pullUpViewController: ISHPullUpViewController, update edgeInsets: UIEdgeInsets, forBottomViewController bottomVC: UIViewController) {
//
//    }



    private func setupLayout(_ pics: [JSON]) {
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

        let sources = pics.map {
            AlamofireSource(urlString: $0.stringValue)!
        }

        print(sources)

        slideshow.setImageInputs(sources)

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTap))
        slideshow.addGestureRecognizer(recognizer)

//        let titles = ["Basic", "Enhancement", "Stack", "StaticTable", "Examples", "Basic", "Enhancement", "Stack", "StaticTable", "Examples"]
//        let table = PlainTable(titles).bg("clear").onClick({ row in
//            print(row.indexPath)
//        })

        let imageViewer = VStack(
                slideshow.pin(.h(self.view.frame.height))
        ).pin(.center)
                .embedIn(self.contentViewController!.view)

        Styles("action").font("14").bg("#000,0.5")

        HStack(
                VStack(
                        "<-->",
//                        Button.styles("action").img("006-chat-bubble").onClick({ _ in
//                            NotificationCenter.default.post(name: NSNotification.Name("openChat"), object: self.uuid)
//                        }).padding(10).radius(10).pin(.wh(50, 50)),
//                        Button.styles("action").img("007-bar-chart").onClick({ _ in
//                            self.onHeart()
//                        }).padding(10).radius(10).pin(.wh(50, 50)),
//                        Button.styles("action").img("009-map").onClick({ _ in
//                            self.onHeart()
//                        }).padding(10).radius(10).pin(.wh(50, 50)),
                        Button.styles("action").img("007-error").onClick({ _ in
                            NotificationCenter.default.post(name: NSNotification.Name("doHide"), object: self.uuid)
                        }).padding(10).radius(10).pin(.wh(50, 50)),
                        Button.styles("action").img("005-success").onClick({ _ in
                            NotificationCenter.default.post(name: NSNotification.Name("doLike"), object: self.uuid)
                        }).padding(10).radius(10).pin(.wh(50, 50)),
                        200
                ).gap(8),
                10
        ).pin(.x(self.contentViewController!.view.frame.width - 60))
                .pin(.y(-200))
                //.bg("green,0.5")
                .pin(.w(60))
                .embedIn(imageViewer)

        //self.buildTagList(self.profile["poly"].arrayValue)

        let avatar: UIImageView = ImageView.img(ToucheApp.Assets.defaultImageName)

        if let mainPic = pics.first {
            avatar.af_setImage(
                    withURL: URL(string: mainPic.stringValue)!,
                    placeholderImage: UIImage(named: ToucheApp.Assets.defaultImageName),
                    filter: AspectScaledToFillSizeCircleFilter(size: CGSize(width: 40.0, height: 40.0))
            )
        }

        self.handleView = ISHPullUpHandleView()

        self.visibleTopBar = VStack(
                HStack(
                        10,
                        avatar.pin(.wh(40, 40)),
                        10,
                        VStack(
                                //Label.str("Benjamin, 37").font("Montserrat-Light,20").color("white").pin(.w(self.bottomViewController!.view.frame.width)),
                                ToucheStatusBar(frame: self.contentViewController!.view.frame, distance: self.profile["dist"].doubleValue, lastSeen: self.profile["seen"].stringValue)
                        ),
                        "<-->",
//                                Button.onClick({ _ in
//
//                                }).img("001-arrows").padding(5).pin(.wh(50, 50)),
                        handleView.pin(.wh(50, 50)),
                        10
                ).pin(.wh(self.bottomViewController!.view.frame.width, 50)),
                10
        )

        VStack(
                visibleTopBar,
                self.buildTags(),
                "<-->"
        ).gap(10)
                .radius(20)
                .pin(.h(self.view.frame.height))
                .embedIn(self.bottomViewController!.view)
    }

    func onHeart() {
        print("heart!!!")
    }

    func tagPressed(title: String, tagView: TagView, sender: TagListView) {
        print("Tag pressed: \(title), \(sender)")
    }

    private func buildTagList(_ tags: [JSON], _ prefix: String, _ title: String) -> CPKStackView? {
        let tagListView = TagListView(frame: CGRect(x: 0, y: 0, width: self.bottomViewController!.view.frame.width, height: self.bottomViewController!.view.frame.height))
        tagListView.autoresizingMask = .flexibleWidth
        tagListView.contentMode = .scaleAspectFit

        tagListView.textFont = Font("Montserrat-Light,15")
        tagListView.textColor = UIColor.white
        tagListView.cornerRadius = 12.0
        tagListView.paddingX = 5.0
        tagListView.paddingY = 5.0
        tagListView.borderWidth = 0.0
        tagListView.shadowColor = UIColor.clear
        tagListView.enableRemoveButton = false
        tagListView.alignment = .left
        tagListView.tagBackgroundColor = UIColor.black.withAlphaComponent(0.5)

        tagListView.delegate = self

        let allTags = tags.map {
            "#\($0.stringValue)"
        }

        if allTags.count == 0 {
            return nil
        }

        let visibleTags = Array(allTags.prefix(5))
        tagListView.addTags(visibleTags)
        return HStack(
                10,
                HStack(
                        VStack(
                                Label.str("\(prefix)").font("Montserrat-Light,24").align(.center).pin(.wh(50, 50)),
                                "<-->"
                        ),
                        tagListView
                ),
                10
        )
    }

    private func buildTags() -> CPKStackView {

        let rows = [
                self.buildTagList(self.profile["keywords"]["poly"].arrayValue, "📍", "Location".translate()),
                self.buildTagList(self.profile["keywords"]["me"].arrayValue, "💪", "I am".translate()),
                self.buildTagList(self.profile["keywords"]["you"].arrayValue, "😍", "Seeking".translate()),
                self.buildTagList(self.profile["keywords"]["like"].arrayValue, "👍", "Like".translate()),
                self.buildTagList(self.profile["keywords"]["dislike"].arrayValue, "👎", "Dislike".translate()),
                self.buildTagList(self.profile["keywords"]["pic_meta"].arrayValue, "✨", "AI".translate())
        ].filter {
            $0 != nil
        }

        return VStack(
                rows
        )
    }
}