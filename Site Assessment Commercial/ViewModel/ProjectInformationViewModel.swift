//
//  ProjectInformationViewModel.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-30.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import Foundation

struct ProjectInformationViewModel {
    var key: String
    var value: String?
    
    init(key: String, value: String?) {
        self.key = key
        self.value = value
    }
}
