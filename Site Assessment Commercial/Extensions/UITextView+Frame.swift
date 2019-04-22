//
//  UITextView+Frame.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-21.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
    func setFrame() {
        let borderColor: UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        
        layer.borderWidth = 0.5
        layer.borderColor = borderColor.cgColor
        layer.cornerRadius = 5.0
    }
}
