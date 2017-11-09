//
//  ReachabilityManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 28/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import SystemConfiguration

class ReachabilityManager {

    static func isConnectedToNetwork() -> Bool {
//        var zeroAddress = sockaddr_in()
//        var flags = SCNetworkReachabilityFlags()
//
//        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
//        zeroAddress.sin_family = sa_family_t(AF_INET)
//
//        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
//            //SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
//        }
//
//        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
//            return false
//        }
//
//        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
//        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
//
//        return (isReachable && !needsConnection)
        return true
    }

}
