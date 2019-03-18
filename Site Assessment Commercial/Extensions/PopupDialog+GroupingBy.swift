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
        
        /*
        let assignedTeamButton = DefaultButton(title: GroupingOptions.assignedTeam.rawValue) {
            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .assignedTeam)
        }
         */
        
        let cancelAction = CancelButton(title: "Cancel", action: nil)
        
        popup.addButtons([statusButton, scheduleDateButton, cancelAction])
        
        return popup
    }
}
