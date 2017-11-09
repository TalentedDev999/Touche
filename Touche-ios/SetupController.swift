//
// Created by Lucas Maris on 7/9/17.
// Copyright (c) 2017 toucheapp. All rights reserved.
//

import Foundation
import UIKit
import Cupcake
import Tabby
import Sparrow
import SwiftLocation
import GTProgressBar
import NVActivityIndicatorView

class SetupController: UIViewController, SPRequestPermissionEventsDelegate {


//    fileprivate func registerForProfileEvents() {
//        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.openChat), name: "openChat")
//    }


    private var messageLabel: UILabel!

//    private var isLoginReady = false
    private var isLocationReady = false
    private var isPermsReady = false
    private var isCognitoReady = false
    private var isToucheUUIDAvailable = false
    private var isTokenReady = false
    private var isFirebaseReady = false
    private var isTwilioReady = false
    private var isIAPReady = false

    private var progressBar: GTProgressBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = ToucheApp.pinkColor

        self.messageLabel = Label.str("Hello!").font("Montserrat-Regular,15").color("white")
//        self.messageLabel = CLTypingLabel()
//        self.messageLabel.font = ToucheApp.Fonts.montserratBig
//        self.messageLabel.color("white")
//        self.messageLabel.charInterval = 0.08

        setupProgressBar()

        //ImageView.img("rabbit").mode(.scaleAspectFit).pin(.center).embedIn(self.view)

        VStack(
                "<-->",
                messageLabel.align(.left).pin(.w(self.view.frame.width)),
                progressBar.pin(.wh(self.view.frame.width, 10)),
                "<-->"
        ).pin(.center)
                .embedIn(self.view, 50, 50, 50, 50)

        //MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onLoginServicesReady), name: EventNames.Login.services_available)

        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onLocationAvailable), name: EventNames.Location.newLocationAvailable)
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onPermissionsAvailable), name: EventNames.Permissions.permsAvailable)
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onPermissionsUnavailable), name: EventNames.Permissions.permsUnavailable)
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onCognitoAvailable), name: EventNames.Login.cognitoIdentityIdAvailable)
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onToucheUUIDAvailable), name: EventNames.Login.toucheUUIDAvailable)
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onTokensReady), name: EventNames.Login.tokensReady)
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onFirebaseReady), name: EventNames.Login.firebaseReady)
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onIAPReady), name: EventNames.Login.iapReady)
        MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onTwilioReady), name: EventNames.Login.twilioReady)



        //MessageBusManager.sharedInstance.addObserver(self, selector: #selector(self.onTwilioReady), name: EventNames.Login.twilioReady)


    }

    private func setupProgressBar() {
        progressBar = GTProgressBar(frame: self.view.frame)

        progressBar.progress = 0
        progressBar.barFillColor = Color("white")!
        progressBar.barBackgroundColor = ToucheApp.pinkColor
        progressBar.barBorderWidth = 0
        progressBar.barFillInset = 0

        progressBar.displayLabel = true
        //progressBar.barBorderColor = UIColor(red: 0.35, green: 0.80, blue: 0.36, alpha: 1.0)
        progressBar.labelTextColor = Color("white")!
        progressBar.progressLabelInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        progressBar.font = ToucheApp.Fonts.montserratBig
        progressBar.labelPosition = GTProgressBarLabelPosition.right
        progressBar.barMaxHeight = 5
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPerms()
    }

    func checkPerms() {
        if PermissionsManager.sharedInstance.arePermsAvailable() {
            MessageBusManager.sharedInstance.postNotificationName(EventNames.Permissions.permsAvailable)
        } else {
            MessageBusManager.sharedInstance.postNotificationName(EventNames.Permissions.permsUnavailable)
        }
    }

    func moveOn() {

        if !PermissionsManager.sharedInstance.home().isModalInPopover {
            self.present(PermissionsManager.sharedInstance.home(), animated: false)
        }

        //self.navigationController?.pushViewController(PermissionsManager.sharedInstance.home(), animated: false)
    }

    func fetchCognitoIdentity() {
        CognitoManager.sharedInstance.getIdentityId {
            (cognitoIdentityId) in
            UserManager.sharedInstance.cognitoIdentityId = cognitoIdentityId
        }
    }

    func updatePB(_ message: String, _ progress: CGFloat) {
//        self.messageLabel.str(message)
        self.messageLabel.text = message
        self.progressBar.animateTo(progress: progress)
    }

    struct ToucheStep {
        let message: String
        let exec: () -> Void
    }

    func flow() {

        let conditions: [Bool] = [
                isPermsReady,
                isLocationReady,
                isCognitoReady,
                isToucheUUIDAvailable,
                isTokenReady,
                isFirebaseReady,
                isIAPReady,
                isTwilioReady
        ]

        let steps: [ToucheStep] = [
                ToucheStep(message: "Fetching permissions...", exec: {
                    self.showPerms()
                }),
                ToucheStep(message: "Acquiring Location...", exec: {
                    GeoManager.sharedInstance.fetchOnce()
                }),
                ToucheStep(message: "Authenticating...", exec: {
                    self.fetchCognitoIdentity()
                }),
                ToucheStep(message: "Computing the meaning of life...", exec: {
                    LoginManager.getToucheUUIDFromCognito()
                }),
                ToucheStep(message: "Did I leave the stove on??...", exec: {
                    UserManager.sharedInstance.login()
                }),
                ToucheStep(message: "Phone...", exec: {
                    PopupManager.sharedInstance.initialize()
                }),
                ToucheStep(message: "Wallet...", exec: {
                    FirebaseTranslationManager.sharedInstance.initialize()
                    FirebasePrefsManager.sharedInstance.setupUserRef()
                    UserManager.sharedInstance.setupIAP()
                    GeoManager.sharedInstance.updateLocation()
                    GeoManager.sharedInstance.fetchBackground()
                }),
                ToucheStep(message: "Keys...", exec: {
                    TwilioChatManager.shared.setUpTwilioClient()
                }),
                ToucheStep(message: "Ready... OK!", exec: {
                    self.moveOn()
                })
        ]

        let progress = CGFloat(Double(conditions.filter {
            $0
        }.count) / Double(conditions.count))
        print("progress=\(progress)")

        let step = conditions.filter {
            $0
        }.count

        print(step)

        self.updatePB(steps[step].message, progress)
        steps[step].exec()

    }

//    func onLoginServicesReady() {
//        self.isLoginReady = true
//        self.flow()
//    }

    func onLocationAvailable() {
        self.isLocationReady = true
        self.flow()
    }

    func onPermissionsAvailable() {
        self.isPermsReady = true
        self.flow()
    }

    func onPermissionsUnavailable() {
        self.isPermsReady = false
        self.flow()
    }

    func onCognitoAvailable() {
        self.isCognitoReady = true
        self.flow()
    }

    func onToucheUUIDAvailable() {
        self.isToucheUUIDAvailable = true
        self.flow()
    }

    func onTokensReady() {
        self.isTokenReady = true
        self.flow()
    }

    func onFirebaseReady() {
        self.isFirebaseReady = true
        self.flow()
    }

    func onTwilioReady() {
        self.isTwilioReady = true
        self.flow()
    }

    func onIAPReady() {
        self.isIAPReady = true
        self.flow()
    }


    func showPerms() {
        SPRequestPermission.dialog.interactive.present(
                on: self,
                with: [
                    SPRequestPermissionType.locationWhenInUse,
                    SPRequestPermissionType.notification,
                    SPRequestPermissionType.photoLibrary,
                    SPRequestPermissionType.camera
                ],
                dataSource: ToucheDataSource(),
                delegate: self
        )
    }

    func didHide() {
        checkPerms()
    }

    func didAllowPermission(permission: SPRequestPermissionType) {
        print("\(permission) is allowed")
    }

    func didDeniedPermission(permission: SPRequestPermissionType) {
        print("\(permission) is denied")
    }

    func didSelectedPermission(permission: SPRequestPermissionType) {
        print("\(permission) is selected")
    }
}

class ToucheDataSource: SPRequestPermissionDialogInteractiveDataSource {
    override open func headerTitle() -> String {
        return "Touché!"
    }

    override open func underDialogAdviceTitle() -> String {
        return ""
    }

    override open func mainColor() -> UIColor {
        return ToucheApp.pinkColor
    }

    override open func secondColor() -> UIColor {
        return UIColor.white
    }

}