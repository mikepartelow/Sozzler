//  Created by mike on 6/15/15.
//  Copyright (c) 2015 mikepartelow.com. All rights reserved.
//

import XCTest
import Sozzler

class RecipeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        XCTAssertEqual(Recipe.fancyName(name: "fancy"), "Fancy", "fancy")
        XCTAssertEqual(Recipe.fancyName(name: " fancy"), "Fancy", "fancy")
        XCTAssertEqual(Recipe.fancyName(name: " fancy "), "Fancy", "fancy")
        XCTAssertEqual(Recipe.fancyName(name: "fancy "), "Fancy", "fancy")
        XCTAssertEqual(Recipe.fancyName(name: "faNcy"), "Fancy", "fancy")
        XCTAssertEqual(Recipe.fancyName(name: "fancy de fance"), "Fancy De Fance", "Fancy")
        XCTAssertEqual(Recipe.fancyName(name: " fancy de fance "), "Fancy De Fance", "Fancy")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }

}
