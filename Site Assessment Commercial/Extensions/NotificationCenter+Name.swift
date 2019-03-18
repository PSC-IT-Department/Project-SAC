//
//  NotificationCenter+Name.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-04.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let didReceiveProcessingMsg      = Notification.Name("Processing")
    static let didReceiveErrorMsg           = Notification.Name("Error")
    static let didReceiveCompleteMsg        = Notification.Name("Completed")
    static let didReceiveWarningMsg         = Notification.Name("Warning")
    static let didReceiveReachabilityMsg    = Notification.Name("Reachability Changed")
}
