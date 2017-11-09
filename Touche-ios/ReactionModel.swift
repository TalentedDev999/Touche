//
//  ReactionModel.swift
//  Touche-ios
//
//  Created by Lucas Maris on 13/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

import Firebase

class ReactionModel {
    
    // MARK: - Properties
    
    struct Reaction {
        static let Value = "value"
        static let Direction = "direction"
        static let Date = "date"
    }
    
    struct TypeName {
        static let defaultName = "default"
        static let photo = "photo"
        static let mood = "mood"
        static let yes_no = "yes_no"
        static let time_increments = "time_increments"
    }
    
    struct Direction {
        static let Empty = ""
        static let Top = "top"
        static let RightTop = "rightTop"
        static let Right = "right"
        static let RightBottom = "rightBottom"
        static let LeftTop = "leftTop"
        static let Left = "left"
        static let LeftBottom = "leftBottom"
        static let bottom = "bottom"
    }
    
    var type:String?
    
    var top:String?
    var rightTop:String?
    var right:String?
    var rightBottom:String?
    var leftTop:String?
    var left:String?
    var leftBottom:String?
    
    // Default Reaction Type
    init() {
        type = TypeName.defaultName
        top = "🃏"
        rightTop = "😂"
        right = "🙂"
        rightBottom = "😐"
        leftBottom = "😑"
        left = "😕"
        leftTop = "😡"
    }

    init(fromSnapshot: DataSnapshot) {
        guard let snapshotDict = fromSnapshot.value as? [String:String] else {
            return
        }
        
        if let top = snapshotDict[Direction.Top] {
            self.top = top
        }
        
        if let rightTop = snapshotDict[Direction.RightTop] {
            self.rightTop = rightTop
        }
        
        if let right = snapshotDict[Direction.Right] {
            self.right = right
        }
        
        if let leftTop = snapshotDict[Direction.LeftTop] {
            self.leftTop = leftTop
        }
        
        if let left = snapshotDict[Direction.Left] {
            self.left = left
        }
        
        if let leftBottom = snapshotDict[Direction.LeftBottom] {
            self.leftBottom = leftBottom
        }
    }
    
    init(type:String, snapshotDict:[String:String]) {
        self.type = type
        
        if type == TypeName.time_increments {
            makeDynamicTimeIncrements()
            return
        }
        
        if let top = snapshotDict[Direction.Top] {
            self.top = top
        }
        
        if let rightTop = snapshotDict[Direction.RightTop] {
            self.rightTop = rightTop
        }
        
        if let right = snapshotDict[Direction.Right] {
            self.right = right
        }
        
        if let rightBottom = snapshotDict[Direction.RightBottom] {
            self.rightBottom = rightBottom
        }
        
        if let leftTop = snapshotDict[Direction.LeftTop] {
            self.leftTop = leftTop
        }
        
        if let left = snapshotDict[Direction.Left] {
            self.left = left
        }
        
        if let leftBottom = snapshotDict[Direction.LeftBottom] {
            self.leftBottom = leftBottom
        }
    }
    
    // MARK: - Methods
    
    fileprivate func makeDefaultType() {
        
    }
    
    func makeDynamicTimeIncrements() {
        type = TypeName.time_increments
        
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        dateFormatter.timeZone = TimeZone.current
        
        rightTop = dateFormatter.string(from: now)
        right = dateFormatter.string(from: now.addingTimeInterval(60 * 15))
        rightBottom = dateFormatter.string(from: now.addingTimeInterval(60 * 30))
        
        leftBottom = dateFormatter.string(from: now.addingTimeInterval(60 * 45))
        left = dateFormatter.string(from: now.addingTimeInterval(60 * 60))
        leftTop = dateFormatter.string(from: now.addingTimeInterval(60 * 75))
    }
    
    func isValid() -> Bool {
        return top != nil && rightTop != nil && right != nil && rightBottom != nil && leftTop != nil && left != nil && leftBottom != nil
    }
    
}
