//
//  JsonManager.swift
//  Touche-ios
//
//  Created by Lucas Maris on 18/7/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class JsonManager {
    
    fileprivate class func getValueOfArray(_ obj:JSON, forFirstKey k1:String, secondKey k2:String? = nil, andThirdKey k3:String? = nil) -> JSON? {
        if k3 != nil && k2 != nil {
            if let auxObj:[JSON] = obj[k1].array, let auxAuxObj:[JSON] = auxObj[0][k2!].array {
                return auxAuxObj[0][k3!]
            }
            return nil
        }
        
        if k2 != nil {
            if let auxObj:[JSON] = obj[k1].array {
                return auxObj[0][k2!]
            }
            return nil
        }
        
        return obj[k1]
    }
    
    fileprivate class func getValueOfJson(_ obj:JSON, forFirstKey k1:String, secondKey k2:String? = nil, andThirdKey k3:String? = nil) -> JSON? {
        if k3 != nil && k2 != nil {
            return obj[k1][k2!][k3!]
        }
        
        if k2 != nil {
            return obj[k1][k2!]
        }
        
        return obj[k1]
    }
    
    // MARK: Methods
    
    // Return array of json objects
    
    class func getArrayJsonValueFrom(_ json:JSON, forFirstKey k1:String, secondKey k2:String? = nil, andThirdKey k3:String? = nil) -> [JSON]? {
        return getValueOfJson(json, forFirstKey: k1, secondKey: k2, andThirdKey: k3)?.array
    }
    
    class func getArrayJsonValueFromJsonArray(_ json:JSON, forFirstKey k1:String, secondKey k2:String? = nil, andThirdKey k3:String? = nil) -> [JSON]? {
        return getValueOfArray(json, forFirstKey: k1, secondKey: k2, andThirdKey: k3)?.array
    }
    
    // Return string
    
    class func getStringValueFrom(_ json:JSON, forFirstKey k1:String, secondKey k2:String? = nil, andThirdKey k3:String? = nil) -> String? {
        return getValueOfJson(json, forFirstKey: k1, secondKey: k2, andThirdKey: k3)?.string
    }
    
    class func getStringValueFromJsonArray(_ json:JSON, forFirstKey k1:String, secondKey k2:String? = nil, andThirdKey k3:String? = nil) -> String? {
        return getValueOfArray(json, forFirstKey: k1, secondKey: k2, andThirdKey: k3)?.string
    }
    
    // Return array of strings
    
    class func getArrayStringValueFrom(_ json:JSON, forFristKey k1:String, secondKey k2:String? = nil, andThirdKey k3:String? = nil) -> [String]? {
        if let jsonArray = getValueOfJson(json, forFirstKey: k1, secondKey: k2, andThirdKey: k3)?.array {
            var retArray = [String]()
            
            jsonArray.forEach({ (value) in
                if let strValue = value.string {
                    retArray.append(strValue)
                }
            })
            
            return retArray
        }
        
        return nil
    }
    
    class func getArrayStringValueFromJsonArray(_ json:JSON, forFirstKey k1:String, secondKey k2:String? = nil, andThirdKey k3:String? = nil) -> [String]? {
        if let jsonArray = getValueOfArray(json, forFirstKey: k1, secondKey: k2, andThirdKey: k3)?.array {
            var retArray = [String]()
            
            jsonArray.forEach({ (value) in
                if let strValue = value.string {
                    retArray.append(strValue)
                }
            })
            
            return retArray
        }
        
        return nil
    }
    
    class func setValue(_ value:String, forFirstKey k1:String, secondKey k2:String? = nil, andThirdKey k3:String? = nil, ofObject obj:inout JSON, atIndex i:Int? = nil) -> Void {
        if i != nil && k2 != nil && k3 != nil {
            obj[k1][i!][k2!][k3!].string  = value
            return
        }
        
        if i != nil && k2 != nil {
            obj[k1][i!][k2!].string = value
            return
        }
        
        obj[k1].string = value
    }
    
}
