//
//  UITableView+ForceDequeueCell.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-04-23.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation
import UIKit

struct CellIdentifier<CellType> {
    let reusableIdentifier: String
}

extension UICollectionView {
    func dequeueReusableCellWithIdentifier<CellType> (
        identifier: CellIdentifier<CellType>,
        forIndexPath indexPath: IndexPath
        ) -> CellType {
        return dequeueReusableCell(
            withReuseIdentifier: identifier.reusableIdentifier,
            for: indexPath
            // swiftlint:disable:next force_cast
            ) as! CellType
    }
}

extension UITableView {
    func dequeueReusableCellWithIdentifier<CellType> (
        identifier: CellIdentifier<CellType>,
        forIndexPath indexPath: IndexPath
        ) -> CellType {
        return dequeueReusableCell(
            withIdentifier: identifier.reusableIdentifier,
            for: indexPath
            // swiftlint:disable:next force_cast
            ) as! CellType
    }
}
