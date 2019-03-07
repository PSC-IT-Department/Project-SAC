//
//  NotificationCenter+Name.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-04.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let didReceiveProcessing      = Notification.Name("didReceiveProcessing")
    static let didReceiveError           = Notification.Name("didReceiveError")
    static let didReceiveComplete        = Notification.Name("didReceiveComplete")
    static let didReceiveWarning         = Notification.Name("didReceiveWarning")
}
