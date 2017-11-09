//
// Created by Lucas Maris on 7/14/17.
// Copyright (c) 2017 toucheapp. All rights reserved.
//

import Foundation
import UIKit
import Cupcake
import MapKit
import SwiftDate
import ISHPullUp
import SwiftyJSON
import TagListView
import AlamofireImage

class ToucheInfoCard: UIView, TagListViewDelegate {

    private var handleView: ISHPullUpHandleView!

    private var profile: JSON?

    private var tagList: CPKStackView!

    var statusBar: ToucheStatusBar!

    var layout: CPKStackView!

    var scrollView: UIScrollView!

    public init(frame: CGRect, handleView: ISHPullUpHandleView) {
        super.init(frame: frame)
        self.handleView = handleView
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func tagPressed(_ title: String, tagView: TagView, sender: TagListView) -> Void {
        print("\(title) pressed!@!")
    }

    @objc func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) -> Void {

    }

    func setup() {

        let avatar: UIImageView = ImageView.img(ToucheApp.Assets.defaultImageName)
        if let profile = self.profile {
            let pics = profile["pic_urls"].arrayValue
            if let mainPic = pics.first {
                avatar.af_setImage(
                        withURL: URL(string: mainPic.stringValue)!,
                        placeholderImage: UIImage(named: ToucheApp.Assets.defaultImageName),
                        filter: AspectScaledToFillSizeCircleFilter(size: CGSize(width: 40.0, height: 40.0)),
                        imageTransition: .flipFromRight(0.5)
                )

            }
        }

        self.tagList = self.buildTags()
        self.scrollView = UIScrollView(frame: UIScreen.main.bounds)
        self.tagList.pin(.w(UIScreen.main.bounds.width)).embedIn(scrollView)

        self.statusBar = ToucheStatusBar(frame: self.frame, distance: 0.0, lastSeen: "")

        self.layout = VStack(
                VStack(
                        HStack(
                                10,
                                avatar.pin(.wh(40, 40)),
                                10,
                                VStack(
                                        self.statusBar
                                ),
                                "<-->",
                                handleView.pin(.wh(50, 50)),
                                10
                        ).pin(.wh(self.frame.width, 50))
                ),
                //self.tagList.pin(.h(self.frame.height))
                scrollView,
                "<-->"
        ).gap(0)
                .radius(20)
                .pin(.h(self.frame.height))
                .embedIn(self)

    }

    private func buildTags() -> CPKStackView {

        if let profile = self.profile {

            let rows = [
                    self.buildTagList(profile["keywords"]["poly"].arrayValue, "📍"),
                    self.buildTagList(profile["keywords"]["me"].arrayValue, "💪"),
                    self.buildTagList(profile["keywords"]["you"].arrayValue, "😍"),
                    self.buildTagList(profile["keywords"]["like"].arrayValue, "👍"),
                    self.buildTagList(profile["keywords"]["dislike"].arrayValue, "👎"),
                    //self.buildTagList(profile["keywords"]["pic_meta"].arrayValue, "✨")
            ].filter {
                $0 != nil
            }

            return VStack(
                    rows,
                    "<-->"
            ).gap(5)
        }

        return VStack()
    }

    private func buildTagList(_ tags: [JSON], _ prefix: String) -> CPKStackView? {
        let tagListView = TagListView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 30, height: UIScreen.main.bounds.height))
        tagListView.autoresizingMask = .flexibleHeight
        tagListView.contentMode = .center

        tagListView.textFont = Font("Montserrat-Regular,13")
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

        let visibleTags = Array(allTags)
        tagListView.addTags(visibleTags)

        return HStack(
                10,
                HStack(
                        VStack(
                                Label.str("\(prefix)").font("Montserrat-Light,15").align(.center).pin(.wh(50, 50)),
                                "<-->"
                        ),
                        tagListView
                ),
                10
        )
    }

    func refresh(_ profile: SwiftyJSON.JSON) {
        self.profile = profile

        self.layout.removeFromSuperview()

        setup()

        let polys = profile["keywords"]["poly"].arrayValue

        self.statusBar.refresh(self.profile!["dist"].doubleValue, self.profile!["seen"].stringValue, polys)
    }
}