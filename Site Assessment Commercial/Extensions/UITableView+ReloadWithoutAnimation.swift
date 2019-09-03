//
//  UITableView+ReloadWithoutAnimation.swift
//  Site Assessment Commercial
//
//  Created by Yu Chen on 2019-08-20.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation
import UIKit

// https://stackoverflow.com/questions/28244475/reloaddata-of-uitableview-with-dynamic-cell-heights-causes-jumpy-scrolling
// Srujan Simha
extension UITableView {

    func reloadWithoutAnimation() {
        let lastScrollOffset = contentOffset
        beginUpdates()
        endUpdates()
        layer.removeAllAnimations()
        setContentOffset(lastScrollOffset, animated: false)
    }
}
