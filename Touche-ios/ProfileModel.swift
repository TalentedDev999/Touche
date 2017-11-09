//
// Created by Lucas Maris on 9/14/16.
// Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

class ProfileModel: NSObject {

    // MARK: Properties

    var uuid:String
    var pic:String?
    var seen:Int64?
    var status:String?
    var endpointArn:String?
    var geohash: String?

    init(uuid:String, pic:String?, seen:Int64?, status: String?, endpointArn: String?, geohash: String?) {
        self.uuid = uuid
        self.pic = pic
        self.seen = seen
        self.status = status
        self.endpointArn = endpointArn
        self.geohash = geohash
    }

}
