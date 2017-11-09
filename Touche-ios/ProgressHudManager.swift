//
//  ProgressHudManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 21/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit
import MBProgressHUD

class ProgressHudManager {
    
    class func blockCustomView(_ view:UIView, withLabel label:String? = nil) -> MBProgressHUD {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        
        if label != nil {
            hud.label.text = label!
        }
        
        view.bringSubview(toFront: hud)
        
        return hud
    }
    
    class func unblockCustomView(_ view:UIView, hud:MBProgressHUD) {
        //Execute the ui unblock operation on the main thread (ui thread) for avoid 
        DispatchQueue.main.async {
            hud.hide(animated: true)
        }
    }
    
    class func toast(_ view:UIView, withLabel label:String, hideAfter:TimeInterval = 3.0) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .text
        hud.label.font = UIFont(name: "Helvetica", size: 12.0)!
        hud.label.text = label
        hud.margin = 10.0
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true)
    }
    
}
