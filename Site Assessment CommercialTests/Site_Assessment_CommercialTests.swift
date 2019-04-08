//
//  Site_Assessment_CommercialTests.swift
//  Site Assessment CommercialTests
//
//  Created by ChenYu on 2019-04-04.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import XCTest

@testable import Site_Assessment_Commercial

class Site_Assessment_CommercialTests: XCTestCase {

    override func setUp() {
        DataStorageService.instantiateSharedInstance()
    }

    override func tearDown() {
    }

    func testExample() {
        
        var q1 = QuestionStructure()
        var q2 = QuestionStructure()
        var q3 = QuestionStructure()
        var q4 = QuestionStructure()
        
        q1.Name = "q1"
        q1.Mandatory = "No"
        q1.Interdependence = "Yes"
        
        q2.Name = "q2"
        q2.Mandatory = "Yes"
        q2.Dependent = ["q1":"Yes"]
        
        q3.Name = "q3"
        
        q4.Name = "q4"
    }

}
