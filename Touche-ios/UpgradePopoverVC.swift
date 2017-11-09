//
//  UpgradePopoverVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 26/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import StoreKit
import PopupDialog
import MBProgressHUD

class UpgradePopoverVC: UIViewController {
    
    // MARK: - Properties
    
    fileprivate struct Segues {
        static let showUpgradePVC = "show upgradePVC"
    }
    
    var popoverDialog:PopupDialog?
    
    internal var upgradeModel = [SKProduct]() { didSet {
        self.upgradeModel.sort { $0.price.doubleValue > $1.price.doubleValue }
        Utils.executeInMainThread { [weak self] in
            self?.table.reloadData()
        }
    } }
    internal var productData = [String:ProductDataModel]()

    internal var hud:MBProgressHUD?
    
    fileprivate var hudTimeOut = 4
    fileprivate var timerCount = 3
    fileprivate let closePopoverLabel = "X"
    
    @IBOutlet weak var closeLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var table: UITableView! {
        didSet {
            table.dataSource = self
            table.delegate = self
        }
    }
    
    // MARK: - Init Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initIAPProducts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        observeIAPTransactions()
        observeSubscriptionChanges()
        countDown()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopObserveIAPTransactions()
        stopObserverSubscriptionChanges()
    }
    
    fileprivate func initIAPProducts() {
        table.becomeFirstResponder()
        
        if IAPManager.sharedInstance.availableProducts.count > 0 {
            upgradeModel = IAPManager.sharedInstance.availableProducts
            productData = IAPManager.sharedInstance.productsData

        } else {
            retrieveIAPProducts()
        }
    }
    
    fileprivate func observeIAPTransactions() {
        let subscriptionChangeEvent = EventNames.Upgrade.subscriptionDidChange
        
        let buyButtonWasPressedEvent = EventNames.Upgrade.buyButtonWasPressed
        let buyButtonWasPressedSelector = #selector(UpgradePopoverVC.tapOnBuyButton)
        
        let transactionFinishedEvent = EventNames.Upgrade.transactionFinished
        let transactionFinishedSelector = #selector(UpgradePopoverVC.iapTransactionFinished)
        
        let transactionErrorEvent = EventNames.Upgrade.transactionError
        let transactionErrorSelector = #selector(UpgradePopoverVC.iapTransactionError)
        
        MessageBusManager.sharedInstance.addObserver(self, selector: transactionFinishedSelector, name: subscriptionChangeEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: buyButtonWasPressedSelector, name: buyButtonWasPressedEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: transactionFinishedSelector, name: transactionFinishedEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: transactionErrorSelector, name: transactionErrorEvent)
    }
    
    fileprivate func observeSubscriptionChanges() {
        let subscriptionChangeSelector = #selector(UpgradePopoverVC.subscriptionDidChange)
        let subscriptionChangeEvent = EventNames.Upgrade.subscriptionDidChange
        
        MessageBusManager.sharedInstance.addObserver(self, selector: subscriptionChangeSelector, name: subscriptionChangeEvent)
    }
    
    fileprivate func stopObserveIAPTransactions() {
        MessageBusManager.sharedInstance.removeObserver(self)
    }
    
    fileprivate func stopObserverSubscriptionChanges() {
        MessageBusManager.sharedInstance.removeObserver(self)
    }
    
    fileprivate func retrieveIAPProducts() {
        let productsIdentifiers = IAPManager.sharedInstance.productsIdentifiers
        self.productData = IAPManager.sharedInstance.productsData
        
        hud = ProgressHudManager.blockCustomView(view)
        hudCountDown()
        
        IAPManager.sharedInstance.requestProducts(Set<String>(productsIdentifiers)) { (products) in
            if let hud = self.hud {
                ProgressHudManager.unblockCustomView(self.view, hud: hud)
            }
            
            if products != nil {
                for product in products! {
                    self.upgradeModel.append(product)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    fileprivate func countDown() {
        Utils.delay(1) { [unowned self] in
            if self.timerCount > 0 {
                self.timerCount -= 1
                self.closeLabel.text = String(self.timerCount)
                self.countDown()
            } else {
                self.closeLabel.text = self.closePopoverLabel
            }
        }
    }
    
    fileprivate func hudCountDown() {
        Utils.delay(1) { 
            if self.hudTimeOut > 0 {
                self.hudTimeOut -= 1
                self.hudCountDown()
            } else {
                if let hud = self.hud {
                    ProgressHudManager.unblockCustomView(self.view, hud: hud)
                }
            }
        }
    }
    
    // MARK: - Events
    
    @IBAction func tapOnCloseDialog(_ sender: AnyObject) {
        if closeLabel.text == closePopoverLabel {
            IAPManager.sharedInstance.closeUpgradePopover()
            popoverDialog?.dismiss()
            PopupManager.sharedInstance.isAlreadyShowing = false
        }
    }
    
    // MARK: - Selectors
    
    func tapOnBuyButton() {
        hud = ProgressHudManager.blockCustomView(view)
    }
    
    func iapTransactionFinished() {
        if let hud = hud {
            ProgressHudManager.unblockCustomView(view, hud: hud)
        }
        
        popoverDialog?.dismiss()
    }
    
    func iapTransactionError() {
        print("transaction error")
        
        if let hud = hud {
            ProgressHudManager.unblockCustomView(view, hud: hud)
        }
    }
    
    func subscriptionDidChange() {
        popoverDialog?.dismiss()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.showUpgradePVC {
            if let upgradePVC = segue.destination as? UpgradePVC {
                upgradePVC.pageControllerDelegate = self
            }
        }
    }
    
}
