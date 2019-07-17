//
//  Site_Assessment_CommercialTests.swift
//  Site Assessment CommercialTests
//
//  Created by ChenYu on 2019-04-04.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import XCTest

@testable import Site_Assessment_Commercial

class SiteAssessmentCommercialTests: XCTestCase {

    override func setUp() {
        DataStorageService.instantiateSharedInstance()
    }

    override func tearDown() {
    }

    func testExample() {
/*
        let string = "1 - 5"
        
        let str = string.split(separator: "-").compactMap({Int($0.trimmingCharacters(in: .whitespaces))})
        
//        print("str = \(str)")
//        print("first = \(str.first)")
//        print("last = \(str.last)")
        
        let array = [
            "1", "2", "3"
        ]
        
        let arr = Array(repeating: array, count: 2).enumerated().compactMap { (offset, element) -> String in
            print("offset  = \(offset)")
            print("element = \(element)")
            
            return "Hello"
        }.joined()
        
        print(arr)

        let arr1 = [
            "1", "2"
        ]
        
        let arr2 = [
            "1", "2", "3"
        ]
        
        let ele = arr2.firstIndex(where: {arr1.contains($0)})
        
        print("ele = \(ele)")
        
*/
        let arr = [1, 2, 3, 4]
        
        let related = arr.filter({$0 % 3 == 0})
        
        print("related = \(related)")
    }

}
