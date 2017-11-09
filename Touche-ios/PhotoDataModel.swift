//
//  PhotoDataModel.swift
//  Touche-ios
//
//  Created by Lucas Maris on 30/9/16.
//  Copyright © 2017 127Thousand LLC. All rights reserved.
//

import UIKit

class PhotoDataModel: NSObject {
    var picUuid = "" {
        didSet {
            path = picUuid != "" ? fileInDocumentsDirectory(picUuid) : nil
        }
    }
    
    var moderationDate:Int?
    var moderated = false
    var adult:Bool?
    var imageHash:String?
    var type:String?
    
    var imageView = UIImageView()
    
    var imageViewHQ = UIImageView()
    var imageViewHQAvailable = false
    
    var path: String?
    
    //var error = false
    
    var downloadProgress: Float = 0
    var downloadComplete = false
    
    var uploadProgress: Float = 0
    var uploadComplete = false
    
    var showHourGlass = false
    var showLock = false
    
    override var description: String { get {return "\nName: \(self.picUuid)"} }
    
    fileprivate func getDocumentsURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL
    }
    
    fileprivate func fileInDocumentsDirectory(_ filename: String) -> String {
        let fileURL = getDocumentsURL().appendingPathComponent(filename)
        return fileURL.path
    }
    
}
