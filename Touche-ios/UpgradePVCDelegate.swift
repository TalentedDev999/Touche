//
//  UpgradePVCDelegate.swift
//  Touche-ios
//
//  Created by Lucas Maris on 20/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


extension UpgradePVC : UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    // MARK: - Page Controller Data source
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = upgradeViewControllers?.index(of: viewController) else { return nil }
        pageControllerDelegate?.upgradePageControllerDidUpdatePageIndex(index)
        
        let previousIndex = index - 1
        
        // Infinite Loop
        guard previousIndex >= 0 else { return upgradeViewControllers?.last }
        
        guard let vc = upgradeViewControllers?[previousIndex] else { return viewController }
        return vc
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = upgradeViewControllers?.index(of: viewController) else { return nil }
        pageControllerDelegate?.upgradePageControllerDidUpdatePageIndex(index)
        
        let nextIndex = index + 1
        
        // Infinite Loop
        guard nextIndex < upgradeViewControllers?.count else { return upgradeViewControllers?.first }
        
        
        guard let vc = upgradeViewControllers?[nextIndex] else { return viewController }
        return vc
    }
    
    // MARK: - Page Controller Delegate
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool)
    {
        if let firstViewController = upgradeViewControllers?.first, let index = viewControllers?.index(of: firstViewController) {
            pageControllerDelegate?.upgradePageControllerDidUpdatePageIndex(index)
        }
    }
    
}
