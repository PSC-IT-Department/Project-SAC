//
//  NotificationCenter+Name.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-04.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let ProcessingMsg      = Notification.Name("Processing")
    static let ErrorMsg           = Notification.Name("Error")
    static let CompleteMsg        = Notification.Name("Completed")
    static let WarningMsg         = Notification.Name("Warning")
    static let ReachabilityMsg    = Notification.Name("Reachability Changed")
}
