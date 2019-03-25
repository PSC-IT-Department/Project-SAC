//
//  PopupDialog+GroupingBy.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-15.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation
import PopupDialog

extension PopupDialog {
    static func showGroupingByDialog() -> PopupDialog {
        let popup = PopupDialog(title: "Grouping By", message: nil, transitionStyle: .zoomIn)
        
        let statusButton = DefaultButton(title: GroupingOptions.status.rawValue) {
            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .status)
        }
        
        let scheduleDateButton = DefaultButton(title: GroupingOptions.scheduleDate.rawValue) {
            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .scheduleDate)
        }
        
        let cancelAction = CancelButton(title: "Cancel", action: nil)
        popup.addButtons([statusButton, scheduleDateButton, cancelAction])
        
        return popup
    }
    
    static func showMapTypeDialog() -> PopupDialog {
        let popup = PopupDialog(title: "Map Type", message: nil, transitionStyle: .zoomIn)
        
        let standardButton = DefaultButton(title: "Standard") {
            DataStorageService.sharedDataStorageService.storeMapTypeOption(option: .standard)
        }

        let satelliteButton = DefaultButton(title: "Satellite") {
            DataStorageService.sharedDataStorageService.storeMapTypeOption(option: .satellite)
        }
        
        let hybridButton = DefaultButton(title: "Hybrid") {
            DataStorageService.sharedDataStorageService.storeMapTypeOption(option: .hybrid)
        }
                
        let cancelAction = CancelButton(title: "Cancel", action: nil)
        popup.addButtons([standardButton, satelliteButton, hybridButton, cancelAction])
        
        return popup
        
    }
}
