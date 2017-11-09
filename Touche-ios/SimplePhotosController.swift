//
// Created by Lucas Maris on 6/29/17.
// Copyright (c) 2017 toucheapp. All rights reserved.
//

import Foundation
import UIKit
import Cupcake

class SimplePhotosController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        Utils.navigationControllerSetup(navigationController)
        Utils.navigationItemSetup(navigationItem)

        navigationController?.isNavigationBarHidden = false

//        self.view.bg("#184367")
//
//        let logo = Label.str("Shubox").color("#FC6560").font("30")
//
//        let navStyle = Styles.color("darkGray").highColor("red").font(15)
//        Styles("btn").color("#FC6560").highColor("white").highBg("#FC6560").font("15").padding(12, 30).border(3, "#FC6560").radius(-1)
//
//        let pricing = Button.str("Pricing").styles(navStyle)
//        let docs = Button.str("Docs").styles(navStyle)
//        let demos = Button.str("Demos").styles(navStyle)
//        let blog = Button.str("Blog").styles(navStyle)
//        let signIn = Button.str("Sign In").styles(navStyle).color("#FC6560")
//
//        let nav = HStack(pricing, docs, demos, blog, signIn).gap(15)
//
//        let simpleFast = Label.str("Simple. Fast. \nCustomizable.").color("#7C60CE").font("30").lines().align(.center)
//        let upload = Label.str("Upload images from your web app directly to Amazon S3.").color("#BE9FDE").font(15).lines().align(.center)
//
//        let startTrial = Button.str("Start Your Free Trial").styles("btn")
//        let image = ImageView.img("splashImage").pin(.ratio)
//
//        let items: [Any] = [logo, 15, nav, 45, simpleFast, 15, upload, 30, startTrial, "<-->", image]
//        VStack(items).align(.center).embedIn(self.view, 10, 15, 0, 15)


    }

}