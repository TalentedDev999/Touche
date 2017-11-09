//
// Created by Lucas Maris on 9/14/16.
// Copyright © 2017 127Thousand LLC. All rights reserved.
//

import Foundation

class PolygonModel: NSObject {

    var id: String
    var name: String
    var nameEnglish: String
    var count: Int

    init(id: String, name: String, nameEnglish: String, count: Int) {
        self.id = id
        self.name = name
        self.nameEnglish = nameEnglish
        self.count = count
    }

}
