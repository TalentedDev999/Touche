//
// Created by Lucas Maris on 6/16/17.
// Copyright (c) 2017 toucheapp. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import TagListView
import Cupcake
import NVActivityIndicatorView

class ToucheCard: UIView {

    var imageLoaded = false

    var backgroundImage: UIImageView!

    var tagListView: TagListView!

    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))

    var profile: JSON!

    var hiddenTags: Bool = false

    var visibleTags: [String] = []

    init(frame: CGRect, profile: JSON) {
        super.init(frame: frame)

        self.profile = profile

        backgroundImage = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))


        self.backgroundColor = UIColor.clear

        tagListView = TagListView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        tagListView.autoresizingMask = .flexibleWidth
        tagListView.contentMode = .scaleAspectFit

        tagListView.textFont = ToucheApp.Fonts.montserratMedium
        tagListView.textColor = UIColor.white
        tagListView.cornerRadius = 12.0
        tagListView.paddingX = 5.0
        tagListView.paddingY = 5.0
        tagListView.borderWidth = 0.0
        tagListView.shadowColor = UIColor.clear
        tagListView.enableRemoveButton = false
        tagListView.alignment = .left
        tagListView.tagBackgroundColor = UIColor.black.withAlphaComponent(0.5)

        //tagListView.addTag(profile["uuid"].stringValue)
        //tagListView.addTag("World")

        let label = UILabel(frame: self.bounds)
        label.text = ""
        label.textAlignment = .center

        let picUuid = profile["pic"].stringValue
        let uuid = profile["uuid"].stringValue

        //backgroundImage.isHidden = true
        tagListView.isHidden = true

        //print(picUuid)

        let imgURL = PhotoManager.sharedInstance.getPhotoURLFromName(picUuid, userUuid: uuid, width: Int(self.frame.width * 2), height: Int(self.frame.height * 2), centerFace: true, flip: true)
        let defaultImage = UIImage(named: ToucheApp.Assets.defaultImageName)

        //print(imgURL)

        backgroundImage.af_setImage(withURL: imgURL,
                placeholderImage: defaultImage,
                //imageTransition: .crossDissolve(0.2),
                completion: { response in
                    //self.addSubviews(self.backgroundImage)
                    self.imageLoaded = true

                    //self.backgroundColor = UIColor(patternImage: self.backgroundImage.image!)

                    self.addSubview(self.backgroundImage)
                    self.sendSubview(toBack: self.backgroundImage)
                    self.backgroundImage.contentMode = UIViewContentMode.scaleAspectFill

                })

        self.backgroundImage.radius(10)

        //self.backgroundColor = UIColor(patternImage: backgroundImage.image!)

        blurEffectView.frame = backgroundImage.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0.0

        //backgroundImage.addSubview(blurEffectView)

        //self.insertSubview(tagListView, aboveSubview: backgroundImage)

        label.font = UIFont.systemFont(ofSize: 48, weight: UIFontWeightThin)
        label.clipsToBounds = true
        label.layer.cornerRadius = 0
        self.addSubview(label)


//        let statusBar = ToucheStatusBar(frame: self.frame, distance: self.profile["dist"].doubleValue, lastSeen: self.profile["seen"].stringValue)
//        statusBar.bg("#000,0.5").radius(-1)
//
//        VStack(
//                "<-->",
//                HStack(
//                        "<-->",
//                        statusBar.pin(.h(30)),
//                        "<-->"
//                ),
//                10
//        ).embedIn(self)


        self.layer.shadowRadius = 4
        self.layer.shadowOpacity = 1.0
        self.layer.shadowColor = UIColor(white: 0.9, alpha: 1.0).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupKeywords(_ maxRows: Int = 4) {

        hiddenTags = false

        tagListView.removeAllTags()

        self.visibleTags = []

        processTags(tags: profile["keywords"]["poly"].arrayValue, emoji: "📍", maxRows: maxRows)
        processTags(tags: profile["keywords"]["me"].arrayValue, emoji: "💪", maxRows: maxRows)
        processTags(tags: profile["keywords"]["you"].arrayValue, emoji: "😍", maxRows: maxRows)
        processTags(tags: profile["keywords"]["like"].arrayValue, emoji: "👍", maxRows: maxRows)
        processTags(tags: profile["keywords"]["dislike"].arrayValue, emoji: "👎", maxRows: maxRows)
        //processTags(tags: profile["keywords"]["pic_meta"].arrayValue, emoji: "👓", maxRows: maxRows)

        //print("setting up keywords \(visibleTags)")

        tagListView.addTags(visibleTags)

        if hiddenTags {
            //tagListView.addTag("more...")
        }

        //print("hidden=\(hiddenTags)")
    }

    private func processTags(tags: [JSON], emoji: String, maxRows: Int) {
        for keyword in tags {

            // 25 chars = 1 row
//            let counts = visibleTags.flatMap({ $0.characters.count })
//            let total = counts.reduce(0, +)
//            let rows = total / 25

            //print("counts =\(counts), total=\(total), rows=\(rows)")
            var numRows = 0
            var currentRowTagCount = 0
            var currentRowWidth: CGFloat = 0
            for (index, tagView) in tagListView.tagViews.enumerated() {
                if currentRowTagCount == 0 || currentRowWidth + tagView.frame.width > self.tagListView.frame.width {
                    numRows += 1
                }
            }

            //print(numRows)
            if numRows < maxRows {
                //if rows < maxRows {
                //tagListView.addTag("\(emoji)\(keyword.stringValue)")
                //self.visibleTags.append("\(emoji)\(keyword.stringValue.truncate(length: 27))")
                self.tagListView.addTag("\(emoji)\(keyword.stringValue.truncate(length: 27))")
            } else {
                self.hiddenTags = true
            }
        }
    }

    func format(placeString: String) -> String {
        let prepositionsAndConjunctions = ["and", "of", "de"]
        guard case let wordList = placeString.components(separatedBy: " ")
                .filter({ !prepositionsAndConjunctions.contains($0.lowercased()) }),
              wordList.count > 1 else {
            return placeString
        }

        return wordList.dropLast()
                .reduce("") {
                    $0 + String($1.characters.first ?? Character("")).uppercased() + "."
                } +
                " " + wordList.last!.withOnlyFirstLetterUppercased()
    }
}

extension String {
    /**
     Truncates the string to the specified length number of characters and appends an optional trailing string if longer.

     - Parameter length: A `String`.
     - Parameter trailing: A `String` that will be appended after the truncation.

     - Returns: A `String` object.
     */
    func truncate(length: Int, trailing: String = "…") -> String {
        if self.characters.count > length {
            return String(self.characters.prefix(length)) + trailing
        } else {
            return self
        }
    }
}

extension String {
    func withOnlyFirstLetterUppercased() -> String {
        guard case let chars = self.characters,
              !chars.isEmpty else {
            return self
        }
        return String(chars.first!).uppercased() +
                String(chars.dropFirst()).lowercased()
    }
}