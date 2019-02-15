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
    let status: String
    let projectAddress: String
        
    static let data:[MainViewModel] = {
        let prj1 = MainViewModel(status: "P",
                                 projectAddress: "657 Black Lake Rd South-Perth-Ontario")
        let prj2 = MainViewModel(status: "D",
                                 projectAddress: "12827 135 St NW-Edmonton-Alberta")
        let prj3 = MainViewModel(status: "P",
                                 projectAddress: "18308 99 Ave NW-Edmonton-Alberta")
        
        return [
            prj1,
            prj2,
            prj3,
        ]
    }()
}
