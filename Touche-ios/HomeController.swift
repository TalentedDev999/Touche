//
// Created by Lucas Maris on 7/2/17.
// Copyright (c) 2017 toucheapp. All rights reserved.
//

import Foundation
import UIKit
import Tabby
import Cupcake
import MoPub
import Tabby

class HomeController: TabbyController, MPAdViewDelegate, TabbyDelegate {

    var adView: MPAdView! = MPAdView(adUnitId: "cd73a4ecd2f145e0a46393d80d12eb4c", size: MOPUB_BANNER_SIZE)

    override public init(items: [TabbyBarItem]) {
        super.init(items: items)


        self.adView.delegate = self

        // Positions the ad at the bottom, with the correct size
        //self.adView.frame = CGRect(x: 0, y: self.view.frame.size.height - 50, width: MOPUB_BANNER_SIZE.width, height: MOPUB_BANNER_SIZE.height)
        self.adView.frame = CGRect(x: (view.frame.size.width / 2) - (MOPUB_BANNER_SIZE.width / 2), y: self.view.frame.height - 50, width: self.view.frame.width, height: 50)
        //self.adView.center = CGPoint(x: view.frame.size.width / 2 - (MOPUB_BANNER_SIZE.width / 2), y: self.adView.center.y)

        self.view.addSubview(self.adView)


        view.addConstraint(NSLayoutConstraint(item: self.tabbyBar, attribute: .bottom, relatedBy: .equal, toItem: self.bottomLayoutGuide, attribute: .bottom, multiplier: 1, constant: -50))
        view.addConstraint(NSLayoutConstraint(item: self.tabbyBar, attribute: .bottom, relatedBy: .equal, toItem: self.adView, attribute: .top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: self.adView, attribute: .top, relatedBy: .equal, toItem: self.tabbyBar, attribute: .bottom, multiplier: 1, constant: 0))
        //view.addConstraint(NSLayoutConstraint(item: self.adView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0))

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            //print("touch!!")
            PeopleManager.sharedInstance.lastTouch = Date()
        }

        super.touchesBegan(touches, with: event)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.frame = CGRect(x: 0, y: 0, width: Utils.screenWidth, height: Utils.screenHeight)

        self.adView.loadAd()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true
        self.view.bringSubview(toFront: self.adView)

        if !PermissionsManager.sharedInstance.arePermsAvailable() {
            self.dismiss(animated: true)
        }

    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func viewControllerForPresentingModalView() -> UIViewController! {
        return self.navigationController!
    }

    func willPresentModalView(forAd view: MPAdView!) {
        if let adUnit = view.adUnitId {
            NSLog("willPresentModalViewForAd: \(adUnit)")
        }
    }

    func didDismissModalView(forAd view: MPAdView!) {
        if let adUnit = view.adUnitId {
            NSLog("didDismissModalViewForAd: \(adUnit)")
        }
    }

    func willLeaveApplication(fromAd view: MPAdView!) {
        if let adUnit = view.adUnitId {
            NSLog("willLeaveApplicationFromAd: \(adUnit)")
        }
    }

    func adViewDidFail(toLoadAd view: MPAdView!) {
        if let adUnit = view.adUnitId {
            NSLog("adViewDidFailToLoadAd: \(adUnit)")
        }
    }

    func adViewDidLoadAd(_ view: MPAdView!) {
        if let adUnit = view.adUnitId {
            NSLog("adViewDidLoadAd: \(adUnit)")
        }
    }

    func tabbyDidPress(_ item: TabbyBarItem) {

        print(item)

        //item.controller.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 150)


//        // Do your awesome transformations!
//        if items.index(of: item) == 1 {
//            mainController.barHidden = true
//        }
//
//        let when = DispatchTime.now() + 2
//        DispatchQueue.main.asyncAfter(deadline: when) {
//            self.mainController.barHidden = false
//        }
    }

    override open func applyNewConstraints(_ controller: UIViewController) {

        super.applyNewConstraints(controller)

        var constant: CGFloat = 0

        if barVisible {
            constant = -(Constant.Dimension.height * 2)
        }

        let constraint = NSLayoutConstraint(
                item: controller.view, attribute: .height,
                relatedBy: .equal, toItem: view,
                attribute: .height, multiplier: 1,
                constant: constant)

        view.addConstraints([constraint])

        view.addConstraint(NSLayoutConstraint(item: controller.view, attribute: .top, relatedBy: .equal, toItem: self.topLayoutGuide, attribute: .top, multiplier: 1, constant: 0))

    }

}
