//
// Created by Lucas Maris on 7/5/17.
// Copyright (c) 2017 toucheapp. All rights reserved.
//

import Foundation
import UIKit
import GTProgressBar
import Cupcake
import SwiftyTimer

protocol ToucheProgressBarDelegate: class {
    func progressBarFinished()
}

class ToucheProgressBar: UIView {

    weak var delegate: ToucheProgressBarDelegate?

    var isPaused: Bool = false {
        didSet {
            if isPaused {

            } else {
                self.startAnimation()
            }
        }
    }

    private var progressBar: GTProgressBar!

    private var t: Timer?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        progressBar = GTProgressBar(frame: frame)

        progressBar.progress = 1
        progressBar.barFillColor = Color("#D40265")!
        progressBar.barBackgroundColor = UIColor.darkGray
        progressBar.barBorderWidth = 0
        progressBar.barFillInset = 0

        progressBar.displayLabel = false
        //progressBar.barBorderColor = UIColor(red: 0.35, green: 0.80, blue: 0.36, alpha: 1.0)
        //progressBar.labelTextColor = Color("#D40265")!
        //progressBar.progressLabelInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        //progressBar.font = UIFont.boldSystemFont(ofSize: 5)
        //progressBar.labelPosition = GTProgressBarLabelPosition.right
        //progressBar.barMaxHeight = 5

        progressBar.embedIn(self)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func startAnimation() {

        print("animating....")

        let durationInMillis = 5000.0
        var millisLeft = durationInMillis

        if let t = t {
            if t.isValid {
                return
            }
        }

        Utils.executeInMainThread {
            //self.progressBar.animateTo(progress: 0.1)
            self.t = Timer.every(100.milliseconds) { (timer: Timer) in

                if !self.isPaused {
                    millisLeft = millisLeft - 100.0
                    //print("millisLeft=\(millisLeft)")

                    self.progressBar.progress = CGFloat(millisLeft / durationInMillis)
                } else {
                    //print("paused")
                }

                if millisLeft <= 0 {
                    timer.invalidate()
                    self.delegate?.progressBarFinished()
                    self.isPaused = true
                }
            }

        }

    }

    func reset() {
        if let t = t {
            if t.isValid {
                t.invalidate()
            }
        }
        self.progressBar.progress = 1.0
    }

}