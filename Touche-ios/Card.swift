//
//  Card.swift
//  Touche-ios
//
//  Created by Lucas Maris on 5/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

import Firebase

class Card:UIView {
    
    let width = Utils.screenWidth * 0.65
    let height = Utils.screenWidth * 0.65 * 1.4
    
    fileprivate let iconFontSize:CGFloat = 100
    
    fileprivate let color = UIColor.black
    fileprivate let size = CGSize(width: 44, height: 44)
    
    fileprivate let degrees = 30
    
    fileprivate var icon:String!
    
    fileprivate var iconLabel:UILabel?
    fileprivate var supLabel:UILabel?
    fileprivate var botLabel:UILabel?
    
    var actionId:String
    var reactionType:String
    
    // MARK: - Init Methods
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(fromAction:ActionModel) {
        actionId = fromAction.id
        reactionType = fromAction.reactionType
        
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height))
        super.init(frame: frame)
        
        icon = fromAction.icon
        
        if reactionType == ReactionModel.TypeName.time_increments {
            initWithMultipleLineLabels()
        } else {
            initIconLabel(icon)
        }
        
        clipsToBounds = true
        layer.borderWidth = 2.0
        layer.cornerRadius = 12.0
        layer.borderColor = UIColor.lightGray.cgColor
        backgroundColor = UIColor.white
    }
            
    fileprivate func initLeftTopIcon() {
    }
    
    fileprivate func initRightBottomIcon() {
    }
    
    fileprivate func initIconLabel(_ icon:String) {
        iconLabel = UILabel(frame: frame)
        iconLabel?.center = center
        iconLabel?.textAlignment = .center
        iconLabel?.font = UIFont(name: "Helvetica", size: iconFontSize)
        iconLabel?.text = icon
        iconLabel?.adjustsFontSizeToFitWidth = true
        iconLabel?.allowsDefaultTighteningForTruncation = true
        
        addSubview(iconLabel!)
    }
    
    fileprivate func initWithMultipleLineLabels() {
        let margin:CGFloat = 48
        let width = frame.width - margin * 2
        let height = (frame.height - margin * 2) / 3
        
        let topLabelFrame = CGRect(x: margin, y: margin, width: width, height: height)
        let midLabelFrame = CGRect(x: margin, y: margin + height, width: width, height: height)
        let botLabelFrame = CGRect(x: margin, y: margin + height * 2, width: width, height: height)
        
        print(height)
        print(midLabelFrame.origin.y)
        print(botLabelFrame.origin.y)
        
        supLabel = UILabel(frame: topLabelFrame)
        iconLabel = UILabel(frame: midLabelFrame)
        botLabel = UILabel(frame: botLabelFrame)
        
        configureLabel(supLabel)
        configureLabel(iconLabel)
        configureLabel(botLabel)
        
        iconLabel?.text = icon
        
        addSubview(supLabel!)
        addSubview(iconLabel!)
        addSubview(botLabel!)
    }

    func getAngle() -> Double {
        let d1 = Int.random(degrees)
        let d2 = Int.random(degrees)
        return Double(d1 - d2)
    }
    
    func getIcon() -> String {
        if let icon = iconLabel?.text {
            return icon
        }
        
        return ""
    }
    
    func updateIcon(_ icon:String) {
        iconLabel?.text = icon
    }
    
    func updateIconFor(_ direction:String, jokerAvailable:Bool? = nil) {
        var reaction:ReactionModel = ReactionModel()
        
        if reactionType == ReactionModel.TypeName.time_increments {
            reaction.makeDynamicTimeIncrements()
            getTimeLabelFor(reaction, direction: direction, jokerAvailable: jokerAvailable)
            return
        }
        
        switch direction {
        case ReactionModel.Direction.Top:
            if jokerAvailable == false {
                iconLabel?.text = icon
            } else {
                iconLabel?.text = reaction.top
            }
            
        case ReactionModel.Direction.RightTop:
            iconLabel?.text = reaction.rightTop
            
        case ReactionModel.Direction.Right:
            iconLabel?.text = reaction.right
            
        case ReactionModel.Direction.RightBottom:
            iconLabel?.text = reaction.rightBottom
            
        case ReactionModel.Direction.LeftTop:
            iconLabel?.text = reaction.leftTop
            
        case ReactionModel.Direction.Left:
            iconLabel?.text = reaction.left
            
        case ReactionModel.Direction.LeftBottom:
            iconLabel?.text = reaction.leftBottom
        
        default:
            iconLabel?.text = icon
        }
    }
    
    fileprivate func getTimeLabelFor(_ reaction:ReactionModel, direction:String, jokerAvailable:Bool?) {
        iconLabel?.text = ""
        supLabel?.text = "🕒"
        
        switch direction {
        case ReactionModel.Direction.Top:
            supLabel?.text = ""
            botLabel?.text = ""
            if jokerAvailable == false {
                iconLabel?.text = icon
            } else {
                iconLabel?.text = reaction.top
            }
            
        case ReactionModel.Direction.RightTop:
            iconLabel?.text = "+0'"
            botLabel?.text = reaction.rightTop!
            
        case ReactionModel.Direction.Right:
            iconLabel?.text = "+15'"
            botLabel?.text = reaction.right!
            
        case ReactionModel.Direction.RightBottom:
            iconLabel?.text = "+30'"
            botLabel?.text = reaction.rightBottom!
            
        case ReactionModel.Direction.LeftTop:
            iconLabel?.text = "+75'"
            botLabel?.text = reaction.leftTop!
            
        case ReactionModel.Direction.Left:
            iconLabel?.text = "+60'"
            botLabel?.text = reaction.left!
            
        case ReactionModel.Direction.LeftBottom:
            iconLabel?.text = "+45'"
            botLabel?.text = reaction.leftBottom!
            
        default:
            botLabel?.text = ""
            supLabel?.text = ""
            iconLabel?.text = icon
        }
    }
    
    fileprivate func configureLabel(_ label:UILabel?) {
        label?.textAlignment = .center
        label?.font = UIFont(name: "Helvetica", size: iconFontSize)
        label?.adjustsFontSizeToFitWidth = true
        label?.allowsDefaultTighteningForTruncation = true
    }
    
    func restoreOriginalIcon() {
        iconLabel?.text = icon
    }
}
