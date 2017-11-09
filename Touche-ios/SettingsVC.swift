//
//  SettingsVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 7/4/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import FBSDKShareKit
import MBProgressHUD
import Eureka
import JSQWebViewController
import Emoji
import PKHUD

class SettingsVC: FormViewController {

    internal var hud: MBProgressHUD?

//    @IBOutlet weak var passwordSwitch: UISwitch!
//    @IBOutlet weak var passwordSwitchLabel: UILabel!
//    @IBOutlet weak var changePasscodeButton: UIButton!

    fileprivate var expirationDateText: String = ""
    fileprivate var productName: String = ""


//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        Utils.navigationControllerSetup(navigationController)
        Utils.navigationItemSetup(navigationItem)

        navigationController?.isNavigationBarHidden = false
        navigationController?.topViewController?.title = "Settings".translate()

        //Utils.setViewBackground(view)

        // todo: translate this stuff

        form +++ Section("Your Profile".translate())
                <<< ButtonRow() {
            $0.tag = "yourPhotos"
            $0.title = "📸 Your Photos".translate()
        }.onCellSelection { cell, row in
            self.navigationController?.pushViewController(UIStoryboard(name: ToucheApp.StoryboardsNames.photos, bundle: nil).instantiateViewController(withIdentifier: "PhotosCollectionVC"), animated: true)
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }
                <<< ButtonRow() {
            $0.tag = "yourKeywords"
            $0.title = "#️⃣ Your Keywords".translate()
        }.onCellSelection { cell, row in
            self.navigationController?.pushViewController(UIStoryboard(name: ToucheApp.StoryboardsNames.profile, bundle: nil).instantiateViewController(withIdentifier: ToucheApp.ViewControllerNames.profileKeywordsVC), animated: true)
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }


//        form +++ Section("Invites".translate())
//                <<< ButtonRow() {
//            $0.tag = "inviteFB"
//            $0.title = "\(":two_men_holding_hands:".emojiUnescapedString) \("Invite Facebook Friends".translate())"
//        }.onCellSelection { cell, row in
//            //FacebookManager.sharedInstance.showFBInvite(self)
//        }.cellSetup() { cell, row in
//            self.setupButtonRowStyles(cell, row: row)
//        }

                +++ Section("Your Membership".translate())
                <<< ButtonRow() {
            $0.tag = "subUpgrade"
            $0.title = "\(":gem:".emojiUnescapedString) \("Become a VIP member".translate())"
            $0.hidden = Condition.function(["subUpgrade"], { form in
                return !(self.productName ?? "").isEmpty
            })
        }.onCellSelection { cell, row in
            IAPManager.sharedInstance.showUpgradePopover(self)
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }
                <<< ButtonRow() {
            $0.tag = "subRestore"
            $0.title = "\(":recycle:".emojiUnescapedString) \("Restore".translate())"
            $0.hidden = Condition.function(["subRestore"], { form in
                return !(self.productName ?? "").isEmpty
            })
        }.onCellSelection { cell, row in
            IAPManager.sharedInstance.restorePurchases()
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }
                <<< LabelRow() {
            $0.tag = "subProductName"
            $0.title = "Product Name".translate()
            $0.value = ""
            $0.hidden = Condition.function(["subUpgrade"], { form in
                return (self.productName ?? "").isEmpty
            })
        }.cellSetup { cell, row in
            cell.backgroundColor = ToucheApp.pinkColor
        }.cellUpdate { cell, row in
            row.value = self.productName
            self.setupLabelRowStyles(cell, row: row)
        }
                <<< LabelRow() {
            $0.tag = "subExpirationDate"
            $0.title = "Expiration Date".translate()
            $0.value = ""
            $0.hidden = Condition.function(["subUpgrade"], { form in
                return (self.productName ?? "").isEmpty
            })
        }.cellSetup { cell, row in
            cell.backgroundColor = ToucheApp.pinkColor
        }.cellUpdate { cell, row in
            row.value = self.expirationDateText
            self.setupLabelRowStyles(cell, row: row)
        }

                +++ Section("Help".translate())
                <<< ButtonRow() {
            $0.tag = "helpSubTerms"
            $0.title = "\(":paperclip:".emojiUnescapedString) \("Subscription Terms".translate())"
        }.onCellSelection { cell, row in
            IAPManager.sharedInstance.showSubscriptionInfo {
                print("done")
            }
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }
                <<< ButtonRow() {
            $0.tag = "helpTOS"
            $0.title = "\(":paperclip:".emojiUnescapedString) \("Terms and Conditions".translate())"
        }.onCellSelection { cell, row in
            self.openURL("https://www.toucheapp.com/tos")
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }
                <<< ButtonRow() {
            $0.tag = "helpPrivacyPolicy"
            $0.title = "\(":paperclip:".emojiUnescapedString) \("Privacy Policy".translate())"
        }.onCellSelection { cell, row in
            self.openURL("https://www.toucheapp.com/privacy-policy")
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }

                +++ Section("Info".translate())
                <<< LabelRow() {
            $0.tag = "infoUUID"
            $0.title = "ID".translate()
            $0.value = UserManager.sharedInstance.toucheUUID!.components(separatedBy: "-")[0]
        }.cellSetup { cell, row in
            cell.backgroundColor = ToucheApp.pinkColor
            self.setupLabelRowStyles(cell, row: row)
        }.cellUpdate { cell, row in
            self.setupLabelRowStyles(cell, row: row)
        }
                <<< LabelRow() {
            $0.tag = "infoVersion"
            $0.title = "Version".translate()
            $0.value = UserManager.sharedInstance.version()
        }.cellSetup { cell, row in
            cell.backgroundColor = ToucheApp.pinkColor
            self.setupLabelRowStyles(cell, row: row)
        }.cellUpdate { cell, row in
            self.setupLabelRowStyles(cell, row: row)
        }

        +++ Section("Utilities".translate())

                <<< SwitchRow() {
            $0.title = "Debug"

            if let savedValue = FirebasePrefsManager.sharedInstance.pref("lambda_local") {
                $0.value = (savedValue as! String == "true")
            } else {
                $0.value = false
            }

        }.onChange {
            if $0.value ?? false {
                FirebasePrefsManager.sharedInstance.save("lambda_local", value: "true")
            } else {
                FirebasePrefsManager.sharedInstance.save("lambda_local", value: "false")
            }
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }

        <<< ButtonRow() {
            $0.tag = "utilsUnblock"
            $0.title = "\(":bomb:".emojiUnescapedString) \("Unblock all".translate())"
        }.onCellSelection { cell, row in
            FirebasePeopleManager.sharedInstance.unblockAll()
            HUD.flash(.progress, delay: 2.0) { finished in
                HUD.flash(.image("\(":thumbsup:".emojiUnescapedString)".image(50, height: 50)), delay: 1.0)
                SoundManager.sharedInstance.playSound(SoundManager.Sounds.pictoBoxSave)
                MessageBusManager.sharedInstance.postNotificationName(EventNames.People.refresh)
            }
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }
                <<< ButtonRow() {
            $0.tag = "utilsUnhide"
            $0.title = "\(":ghost:".emojiUnescapedString) \("Unhide all".translate())"
        }.onCellSelection { cell, row in
            FirebasePeopleManager.sharedInstance.dumpHides() { map in

            }
            HUD.flash(.progress, delay: 2.0) { finished in
                HUD.flash(.image("\(":thumbsup:".emojiUnescapedString)".image(50, height: 50)), delay: 1.0)
                SoundManager.sharedInstance.playSound(SoundManager.Sounds.pictoBoxSave)
                MessageBusManager.sharedInstance.postNotificationName(EventNames.People.refresh)
            }
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }

                <<< ButtonRow() {
            $0.tag = "utilsDumpAll"
            $0.title = "\(":ghost:".emojiUnescapedString) \("Dump all".translate())"
        }.onCellSelection { cell, row in
            FirebasePeopleManager.sharedInstance.dumpAll() { map in

            }
            HUD.flash(.progress, delay: 2.0) { finished in
                HUD.flash(.image("\(":thumbsup:".emojiUnescapedString)".image(50, height: 50)), delay: 1.0)
                SoundManager.sharedInstance.playSound(SoundManager.Sounds.pictoBoxSave)
                MessageBusManager.sharedInstance.postNotificationName(EventNames.People.refresh)
            }
        }.cellSetup() { cell, row in
            self.setupButtonRowStyles(cell, row: row)
        }

        self.tableView?.backgroundColor = ToucheApp.pinkColor
        self.tableView?.separatorColor = UIColor.clear
    }

    func setupLabelRowStyles(_ cell: BaseCell, row: BaseRow) {
        cell.textLabel?.font = UIFont(name: ToucheApp.Fonts.Light.montserrat, size: ToucheApp.Fonts.Sizes.medium)
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.detailTextLabel?.font = UIFont(name: ToucheApp.Fonts.Light.montserrat, size: ToucheApp.Fonts.Sizes.medium)
    }

    func setupButtonRowStyles(_ cell: BaseCell, row: BaseRow) {
        cell.backgroundColor = UIColor(red: 0.23, green: 0.23, blue: 0.27, alpha: 1.00)
        cell.tintColor = UIColor.white
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(red: 0.66, green: 0.04, blue: 0.05, alpha: 1.0)
        cell.selectedBackgroundView = bgColorView
        cell.textLabel?.font = UIFont(name: ToucheApp.Fonts.Regular.montserrat, size: ToucheApp.Fonts.Sizes.big)
    }

    func openURL(_ urlString: String) {

        let pre = Locale.preferredLanguages[0]

        var url = urlString

        if !pre.contains("en") {
            url = "https://translate.google.com/translate?js=n&sl=auto&tl=" + pre + "&u=" + urlString
        }

        if let checkURL = URL(string: url) {
            let controller = WebViewController(url: checkURL)
            let nav = UINavigationController(rootViewController: controller)
            self.present(nav, animated: true, completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateUpgradeView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        observeIAPTransactions()
    }

    // MARK: - Helper Methods

    fileprivate func observeIAPTransactions() {
        let subscriptionChangeEvent = EventNames.Upgrade.subscriptionDidChange

        let transactionFinishedEvent = EventNames.Upgrade.transactionFinished
        let transactionFinishedSelector = #selector(SettingsVC.iapTransactionFinished)

        let transactionErrorEvent = EventNames.Upgrade.transactionError
        let transactionErrorSelector = #selector(SettingsVC.iapTransactionError)

        MessageBusManager.sharedInstance.addObserver(self, selector: transactionFinishedSelector, name: subscriptionChangeEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: transactionFinishedSelector, name: transactionFinishedEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: transactionErrorSelector, name: transactionErrorEvent)
    }

    fileprivate func updateUpgradeView() {
        if UserManager.sharedInstance.isPremium() {
            guard let currentSubscription = IAPManager.sharedInstance.currentSubscription else {
                return
            }
            if !currentSubscription.isAValidSubscription() {
                return
            }

            let localizedProductTitle = IAPManager.sharedInstance.getLocalizedProductTitleFrom(currentSubscription.productId!)
            let expirationDate = Double(currentSubscription.expirationDate!)

            if localizedProductTitle != nil {
                productName = localizedProductTitle!

            }

            if expirationDate != nil {
                expirationDateText = Date(timeIntervalSince1970: expirationDate! / 1000).description
            }

            // todo: display expiration!!

            navigationItem.rightBarButtonItem = nil
        } else {

        }

        // always refresh form
        self.form.rowBy(tag: "subProductName")?.updateCell()
        self.form.rowBy(tag: "subExpirationDate")?.updateCell()
        self.form.rowBy(tag: "subUpgrade")?.evaluateHidden()
        self.form.rowBy(tag: "subRestore")?.evaluateHidden()
        self.form.rowBy(tag: "subProductName")?.evaluateHidden()
        self.form.rowBy(tag: "subExpirationDate")?.evaluateHidden()

    }

    // MARK: - Selectors

    func iapTransactionFinished() {
        if let hud = self.hud {
            ProgressHudManager.unblockCustomView(view, hud: hud)
        }

        updateUpgradeView()
    }

    func iapTransactionError() {
        if let hud = self.hud {
            ProgressHudManager.unblockCustomView(view, hud: hud)
        }

        if let transactionErrorMessage = IAPManager.sharedInstance.transactionErrorMessage {
            NotificationsManager.sharedInstance.showError(transactionErrorMessage)
        }
    }

    func backHandler(_ sender: AnyObject) {
        let _ = navigationController?.popViewController(animated: true)
    }

    // MARK: - Events

    @IBAction func tapOnRestore(_ sender: UIBarButtonItem) {
        if !UserManager.sharedInstance.isPremium() {
            IAPManager.sharedInstance.restorePurchases()
            hud = ProgressHudManager.blockCustomView(view)
        }
    }

    @IBAction func tapOnSubscription() {
        IAPManager.sharedInstance.showUpgradePopover(self)
    }

    @IBAction func tapOnInviteFriends(_ sender: UIButton) {
        FacebookManager.sharedInstance.showFBInvite(self)
    }


    @IBAction func passwordSwitchHandler(_ sender: UISwitch) {

    }

    @IBAction func changePasscodeHandler(_ sender: UIButton) {

    }

}
