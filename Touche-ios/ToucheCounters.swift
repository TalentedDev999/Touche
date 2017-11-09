//
// Created by Lucas Maris on 7/5/17.
// Copyright (c) 2017 toucheapp. All rights reserved.
//

import Foundation
import UIKit
import Cupcake
import SwiftyJSON

class ToucheCounters: UIView {

    var matchCounter: UIButton!
    var likeCounter: UIButton!
    var hideCounter: UIButton!
    var experienceCounter: UIButton!

    var counterData: [String: Int]! = [
            "credits": 0,
            "exp": 0
    ]

    public override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setup() {

        Styles("counter").font("Montserrat-Regular,15").bg("#D40265").padding(8)

        likeCounter = Button.styles("counter").radius(-1).onClick({ _ in
            NotificationCenter.default.post(name: NSNotification.Name("viewLikes"), object: nil)
        })
        matchCounter = Button.styles("counter").radius(-1).onClick({ _ in

        })
        hideCounter = Button.styles("counter").radius(-1).onClick({ _ in
            NotificationCenter.default.post(name: NSNotification.Name("dumpHides"), object: nil)
        })
        experienceCounter = Button.styles("counter").radius(-1).onClick({ _ in

        })

        HStack(
                "<-->",
                matchCounter,
                likeCounter,
                hideCounter,
                experienceCounter,
                "<-->"
        ).gap(8).embedIn(self, 0, 0, 0, 0)

        // todo retrieve from cache!
        self.refreshCounters([
                "mutual_likes": 0,
                "like": 0,
                "hide": 0,
                "credits": 0,
                "exp": 0
        ])
    }

    public func refreshCounters(_ map: [String: Int]) {
        print(map)

        self.counterData = map

        if let mutual_likes = map["mutual_likes"] {
            self.matchCounter.str("👬 \(mutual_likes)")
        }
        if let likes = map["like"] {
            self.likeCounter.str("⭐️ \(likes)")
        }
        if let hides = map["hide"] {
            self.hideCounter.str("🕶\(hides)")
        }
        if let exp = map["exp"] {
            self.experienceCounter.str("🥕️ \(exp)")
        }
    }

    func initialize() {
        AWSLambdaManager.sharedInstance.fetchLists() { result, exception, error in
            if result != nil {
                let jsonResult = JSON(result!)
                self.refreshCounters([
                        "mutual_likes": jsonResult["mutual_likes"].intValue,
                        "like": jsonResult["like"].intValue,
                        "hide": jsonResult["hide"].intValue,
                        "credits": jsonResult["credits"].intValue,
                        "exp": jsonResult["exp"].intValue
                ])
            }
        }
    }

}