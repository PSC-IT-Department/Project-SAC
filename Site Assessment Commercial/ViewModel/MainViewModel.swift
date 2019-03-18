//
//  MainViewModel.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import RxSwift
import RxCocoa
import RxDataSources

struct MainViewModel: IdentifiableType, Equatable {
    var identity: Int?
    var status: UploadStatus
    var projectAddress: String
    
    init(status: UploadStatus, projectAddress: String) {
        self.status = status
        self.projectAddress = projectAddress
    }
}
