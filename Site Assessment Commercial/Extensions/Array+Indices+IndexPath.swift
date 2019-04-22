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
extension Array where Element: Collection, Element.Index == Int {
    func indices(where predicate: (Element.Iterator.Element) -> Bool) -> (Int, Int)? {
        for (i, row) in self.enumerated() {
            if let j = row.firstIndex(where: predicate) {
                return (i, j)
            }
        }
        return nil
    }
    
    func indexPath(where predicate: (Element.Iterator.Element) -> Bool) -> IndexPath? {
        for (i, row) in self.enumerated() {
            if let j = row.firstIndex(where: predicate) {
                return IndexPath(indexes: [i, j])
            }
        }
        return nil
    }
}

/*
 https://stackoverflow.com/questions/40010345/in-swift-an-efficient-function-that-separates-an-array-into-2-arrays-based-on-a @neoneye
 let numbers = [1,2,3,4,5,6,7,8,9,10]
 let (divisibleBy3, theRest) = numbers.stablePartition { $0 % 3 == 0 }
 print("divisible by 3: \(divisibleBy3), the rest: \(theRest)")
 // divisible by 3: [3, 6, 9], the rest: [1, 2, 4, 5, 7, 8, 10]
 
 */
extension Array {
    func stablePartition(by condition: (Element) -> Bool) -> ([Element], [Element]) {
        var matching = [Element]()
        var nonMatching = [Element]()
        for element in self {
            if condition(element) {
                matching.append(element)
            } else {
                nonMatching.append(element)
            }
        }
        return (matching, nonMatching)
    }
}
