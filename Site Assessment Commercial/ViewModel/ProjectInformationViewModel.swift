//
//  ProjectInformationViewModel.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-30.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import Foundation

enum ProjectStatus {
    case Pending
    case Completed
    case Failed
    case Uploading
}

struct ProjectInformationViewModel {
    var key: String
    var value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    static let data: [ProjectInformationViewModel] = {
        let prjAddr = ProjectInformationViewModel(key: "Project Address", value: "123123123")
        let prjId = ProjectInformationViewModel(key: "Project ID", value: "123123123")
        
        return [prjAddr, prjId]
    }()

    func configure() {
    
    }

}
