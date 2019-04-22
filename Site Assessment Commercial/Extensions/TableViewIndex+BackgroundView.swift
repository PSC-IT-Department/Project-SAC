//
//  TableViewIndex+BackgroundView.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-28.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation
import UIKit

// MARK: TableViewIndexBackground
class BackgroundView: UIView {
    
    enum Alpha: CGFloat {
        case normal = 0.3
        case highlighted = 0.6
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 6
        layer.masksToBounds = false
        backgroundColor = UIColor.lightGray.withAlphaComponent(Alpha.normal.rawValue)
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
