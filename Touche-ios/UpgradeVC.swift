//
//  UpgradeVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 9/12/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import StoreKit
import MBProgressHUD

class UpgradeVC: UIViewController {
    
    // MARK: - Properties
    
    fileprivate struct Segues {
        static let showUpgradePVC = "show upgradePVC"
    }
    
    internal var upgradeModel = [SKProduct]() {
        didSet {
            self.upgradeModel.sort {
                $0.price.doubleValue > $1.price.doubleValue
            }
            Utils.executeInMainThread { [weak self] in
                self?.table.reloadData()
            }
        }
    }
    
    internal var productData = [String:ProductDataModel]()
    
    internal var hud:MBProgressHUD?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var expirationView: UIView! { didSet { expirationView.isHidden = true; expirationView.roundViewWith(8) } }
    @IBOutlet weak var expirationLabel: UILabel! { didSet { expirationLabel.isHidden = true } }
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var table: UITableView! {
        didSet {
            table.dataSource = self
            table.delegate = self
        }
    }
    
    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.navigationControllerSetup(navigationController)
        Utils.navigationItemSetup(navigationItem)
        Utils.setViewBackground(view)
        
        initIAPProducts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        updateUpgradeView()
        observeIAPTransactions()
        
        FirebaseChatManager.sharedInstance.currentNavigationController = navigationController
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        MessageBusManager.sharedInstance.removeObserver(self)
    }
    
    // MARK: - Init Methods
    
    fileprivate func initIAPProducts() {
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
        let buyButtonWasPressedSelector = #selector(UpgradeVC.tapOnBuyButton)
        
        let transactionFinishedEvent = EventNames.Upgrade.transactionFinished
        let transactionFinishedSelector = #selector(UpgradeVC.iapTransactionFinished)
        
        let transactionErrorEvent = EventNames.Upgrade.transactionError
        let transactionErrorSelector = #selector(UpgradeVC.iapTransactionError)
        
        MessageBusManager.sharedInstance.addObserver(self, selector: transactionFinishedSelector, name: subscriptionChangeEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: buyButtonWasPressedSelector, name: buyButtonWasPressedEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: transactionFinishedSelector, name: transactionFinishedEvent)
        MessageBusManager.sharedInstance.addObserver(self, selector: transactionErrorSelector, name: transactionErrorEvent)
    }
    
    fileprivate func retrieveIAPProducts() {
        let productsIdentifiers = IAPManager.sharedInstance.productsIdentifiers
        productData = IAPManager.sharedInstance.productsData
        
        hud = ProgressHudManager.blockCustomView(view)
        
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
    
    fileprivate func updateUpgradeView() {
        if UserManager.sharedInstance.isPremium() {
            guard let currentSubscription = IAPManager.sharedInstance.currentSubscription else { return }
            if !currentSubscription.isAValidSubscription() { return }
            
            let localizedProductTitle = IAPManager.sharedInstance.getLocalizedProductTitleFrom(currentSubscription.productId!)
            let expirationDate = Double(currentSubscription.expirationDate!)
            var expirationText = ""
            
            if localizedProductTitle != nil {
                expirationText = localizedProductTitle!
            }
            
            if expirationDate != nil {
                expirationText += "\n Expires in: " + Date(timeIntervalSince1970: expirationDate! / 1000).string(dateStyle: .medium)
            }
            
            expirationLabel.text = expirationText
            
            expirationView.isHidden = false
            expirationLabel.isHidden = false
            
            table.isHidden = true
            removeRestorePurchaseItem()
        } else {
            table.isHidden = false
            expirationView.isHidden = true
            expirationLabel.isHidden = true
            expirationLabel.text = ""
        }
    
    }
    
    fileprivate func removeRestorePurchaseItem() {
        navigationItem.rightBarButtonItem = nil
    }
    
    // MARK: - Selectors
    
    @IBAction func tapOnRestore(_ sender: UIBarButtonItem) {
        if !UserManager.sharedInstance.isPremium() {
            IAPManager.sharedInstance.restorePurchases()
            hud = ProgressHudManager.blockCustomView(view)
        }
    }
    
    func tapOnBuyButton() {
        hud = ProgressHudManager.blockCustomView(view)
    }
    
    func iapTransactionFinished() {
        if let hud = self.hud {
            ProgressHudManager.unblockCustomView(view, hud: hud)
        }
        
        updateUpgradeView()
        Utils.executeInMainThread { [weak self] in
            self?.table.reloadData()
        }
    }
    
    func iapTransactionError() {
        if let hud = self.hud {
            ProgressHudManager.unblockCustomView(view, hud: hud)
        }
        
        if let transactionErrorMessage = IAPManager.sharedInstance.transactionErrorMessage {
            NotificationsManager.sharedInstance.showError(transactionErrorMessage)
        }
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
