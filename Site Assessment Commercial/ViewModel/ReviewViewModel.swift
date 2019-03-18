//
//  ReviewViewModel.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-02-28.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation

struct ReviewViewModel {
    var key: String
    var value: String?
    
    init() {
        self.key = ""
        self.value = ""
    }
    
    init(key: String, value: String?) {
        self.key = key
        self.value = value
    }
}
