//
//  Site_Assessment_CommercialUITests.swift
//  Site Assessment CommercialUITests
//
//  Created by ChenYu on 2019-04-04.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import XCTest

@testable import Site_Assessment_Commercial
@testable import Pods_Site_Assessment_Commercial

class SiteAssessmentCommercialUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()

        app.launch()

    }

    override func tearDown() {
    }
}

extension SiteAssessmentCommercialUITests {
    func goBack() {
        wait(interval: 1.0)
        let window = app.windows.element(boundBy: 0)
        window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 40, dy: 30)).tap()
        wait(interval: 1.5)
    }
    
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 2, file: String = #file, line: Int = #line) {
        let existsPredicate = NSPredicate(format: "exists == true")
        
        expectation(for: existsPredicate,
                    evaluatedWith: element,
                    handler: nil)
        
        waitForExpectations(timeout: timeout) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after \(timeout) seconds."
                self.recordFailure(withDescription: message, inFile: file, atLine: line, expected: true)
            }
        }
    }
    
    func wait(interval: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(interval))
    }
}

extension SiteAssessmentCommercialUITests {
    func testSettingsVC() {
        app.launch()
        
        XCTAssert(app.navigationBars.allElementsBoundByIndex[0].buttons["Menu"].exists)
        
        // Tap on Settings icon
        app.navigationBars.allElementsBoundByIndex[0].buttons["Menu"].tap()

        // Tap on Grouping by
        app.tables.allElementsBoundByIndex[0].cells.allElementsBoundByIndex[0].tap()

        // Tap on 1st option
        app.buttons["Status"].tap()
        
        goBack()
        
        let tableViewHeader = app.tables.allElementsBoundByIndex[0].otherElements["MainTableViewHeader"]
        
        wait(interval: 1.0)
    }
    
    func testVC() {
    }
}
