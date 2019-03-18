//
//  Array+Indices+IndexPath.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-16.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation

/*
 https://stackoverflow.com/questions/37314322/how-to-find-the-index-of-an-item-in-a-multidimensional-array-swiftily
 
 print(testArray.indices(of: testNumber))
 print(testArray.indices{$0 == testNumber})
 
 Optional((1, 2))
 Optional((1, 2))
 
 */
extension Array where Element : Collection, Element.Index == Int {
    func indices(where predicate: (Element.Iterator.Element) -> Bool) -> (Int, Int)? {
        for (i, row) in self.enumerated() {
            if let j = row.index(where: predicate) {
                return (i, j)
            }
        }
        return nil
    }
    
    func indexPath(where predicate: (Element.Iterator.Element) -> Bool) -> IndexPath? {
        for (i, row) in self.enumerated() {
            if let j = row.index(where: predicate) {
                return IndexPath(indexes: [i, j])
            }
        }
        return nil
    }
}
