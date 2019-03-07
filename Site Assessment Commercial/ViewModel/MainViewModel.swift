//
//  MainViewModel.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import RxSwift
import RxCocoa

struct MainViewModel {
    var status: String
    var projectAddress: String
    
    init(status: String, projectAddress: String) {
        self.status = status
        self.projectAddress = projectAddress
    }
}
