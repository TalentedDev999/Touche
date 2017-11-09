//
//  ProvisioningProfileParser.swift
//  Mapsv2
//
//  Created by Andrew Goodwin on 6/28/16.
//  Copyright © 2016 Conway Corporation. All rights reserved.
//

import Foundation

class ProvisioningProfileParser: NSObject {

    fileprivate var successfulProvisioningProfileParseClosure: (() -> Void)? = nil

    init(success: @escaping (() -> Void)) {
        super.init()
        successfulProvisioningProfileParseClosure = success
        let priority = DispatchQueue.GlobalQueuePriority.default
        DispatchQueue.global(priority: priority).async {
            if let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") {
                let data = try? Data(contentsOf: URL(fileURLWithPath: path))
                if data != nil {

                    let dataString = NSString(data: data!, encoding: String.Encoding.isoLatin1.rawValue)

                    let scanner = Scanner(string: dataString! as String)

                    var ok = scanner.scanUpTo("<plist", into: nil)
                    if ok {
                        var plistString: NSString? = ""
                        ok = scanner.scanUpTo("</plist>", into: &plistString)
                        if ok {
                            plistString = plistString!.appending("</plist>") as NSString
                            //print(plistString)
                            let plistData = plistString!.data(using: String.Encoding.isoLatin1.rawValue)
                            do {
                                let mobileProvision = try PropertyListSerialization.propertyList(from: plistData!, options: PropertyListSerialization.MutabilityOptions(), format: nil)

                                let mp = mobileProvision as! NSDictionary

                                ProvisioningProfile.sharedProfile.appName = mp.object(forKey: "AppIDName") as! String
                                ProvisioningProfile.sharedProfile.creationDate = mp.object(forKey: "CreationDate") as! Date
                                ProvisioningProfile.sharedProfile.expirationDate = mp.object(forKey: "ExpirationDate") as! Date
                                let entitlements = mp.object(forKey: "Entitlements") as! NSDictionary
                                if let debug = entitlements.object(forKey: "get-task-allow") as? Bool {
                                    ProvisioningProfile.sharedProfile.isDebug = debug
                                }
                                ProvisioningProfile.sharedProfile.appId = entitlements.object(forKey: "application-identifier") as! String
                                ProvisioningProfile.sharedProfile.teamId = entitlements.object(forKey: "com.apple.developer.team-identifier") as! String
                                ProvisioningProfile.sharedProfile.teamName = mp.object(forKey: "TeamName") as! String
                                ProvisioningProfile.sharedProfile.ttl = mp.object(forKey: "TimeToLive") as! Int
                                ProvisioningProfile.sharedProfile.name = mp.object(forKey: "Name") as! String

                                DispatchQueue.main.async {
                                    self.successfulProvisioningProfileParseClosure!()
                                }
                            } catch {

                            }

                        }
                    }
                }
            } else {
                ProvisioningProfile.sharedProfile.isDebug = true
                DispatchQueue.main.async {
                    self.successfulProvisioningProfileParseClosure!()
                }
            }
        }

    }
}
