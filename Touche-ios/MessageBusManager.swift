//
//  MessageBusManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 18/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

class MessageBusManager {

    static let sharedInstance = MessageBusManager()
    
    fileprivate let nc:NotificationCenter
    
    fileprivate init() {
        nc = NotificationCenter.default
    }
    
    func addObserver(_ observer:AnyObject, selector:Selector, name:String?, object:AnyObject? = nil) -> Void {
        nc.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: name!), object: object)
    }
    
    func removeObserver(_ observer:AnyObject) -> Void {
        nc.removeObserver(observer)
    }
    
    func postNotificationName(_ name:String, object:AnyObject? = nil) -> Void {
        print("posting event: \(name)=\(object)")
        nc.post(name: Notification.Name(rawValue: name), object: object)
    }
    
}
