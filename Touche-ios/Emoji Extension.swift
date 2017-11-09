//
//  Chatto Extension.swift
//  Touche-ios
//
//  Created by Lucas Maris on 27/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func image(_ width: Int, height: Int) -> UIImage? {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        UIColor.clear.set()
        let rect = CGRect(origin: CGPoint.zero, size: size)
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        (self as NSString).draw(in: rect, withAttributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 50)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    func translate() -> String {
        return FirebaseTranslationManager.sharedInstance.translate(self)
    }
}
