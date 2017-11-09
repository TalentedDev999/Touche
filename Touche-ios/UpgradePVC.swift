//
//  UpgradePVC.swift
//  Touche-ios
//
//  Created by Lucas Maris on 20/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import Foundation
import GameplayKit

class UpgradePVC: UIPageViewController {
    
    // MARK: - Properties
    
    fileprivate let UpgradeCarouselViewControllerIdentifier = "Upgrade Carousel"
    fileprivate var changeCarouselImage:(() -> Void)?
    
    internal var upgradeViewControllers:[UIViewController]?
    internal var index = 0
    
    var pageControllerDelegate:UpgradePageControllerDelegate?
    
    // MARK: - Init Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        initCarousel()
        initChangeCarouselImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateCarouselImage()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        changeCarouselImage = nil
    }
    
    fileprivate func initCarousel() {
        
        upgradeViewControllers = []

        // todo load text and images from the backend

        let image = UIImage(named: "silk")

        upgradeViewControllers?.append(getViewControllerWith(image, text: "VIP Membership".translate()))

        if let viewControllers = upgradeViewControllers {
            pageControllerDelegate?.upgradePageControllerDidUpdatePageCount(viewControllers.count)
        }
        
        if let currentVC = upgradeViewControllers?[index] {
            setViewControllers([currentVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    fileprivate func initChangeCarouselImage() {
        changeCarouselImage = {
            if self.upgradeViewControllers == nil { return }
            
            let carouselSize = self.upgradeViewControllers!.count
            self.index = (self.index + 1) % carouselSize
            
            if let auxVC = self.upgradeViewControllers?[self.index] {
                self.setViewControllers([auxVC], direction: .forward, animated: true, completion: nil)
                self.pageControllerDelegate?.upgradePageControllerDidUpdatePageIndex(self.index)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    fileprivate func getViewControllerWith(_ image:UIImage? = nil, text:String? = nil) -> UIViewController {
        let upgradeStoryboradName = ToucheApp.StoryboardsNames.upgrade
        let upgradeStoryboard = UIStoryboard(name: upgradeStoryboradName, bundle: nil)
        let upgradeCarouselViewController = upgradeStoryboard.instantiateViewController(withIdentifier: UpgradeCarouselViewControllerIdentifier)
        
        if let ucvc = upgradeCarouselViewController as? UpgradeCarouselVC {
            if let image = image {
                ucvc.image = image
            }
            
            if let text = text {
                ucvc.textLabel = text
            }
            
            return ucvc
        }
        
        return upgradeCarouselViewController
    }
    
    fileprivate func updateCarouselImage() {
        if let changeCarouselImage = changeCarouselImage {
            Utils.delay(3) { [unowned self] in
                changeCarouselImage()
                self.updateCarouselImage()
            }
        }
    }
    
}
