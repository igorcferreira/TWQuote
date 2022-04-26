//
//  TWQuoteTests.swift
//  TWQuoteTests
//
//  Created by Fernando Bunn on 03/05/2019.
//  Copyright © 2019 Fernando Bunn. All rights reserved.
//

import XCTest
@testable import TWQuote

class TWQuoteTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testURLParsing() {
        let onlyHostURL = URL(string: "https://some.beautiful.cat")
        let hostAndQueryURL = URL(string: "https://some.beautiful.cat?at=window")
        
        let queryParametes = [
            "Some": "Valid",
            "Another": "With non-URL safe %20 value",
            "Other%20Key": "And value & as non-URL Safe?"
        ]
        
        let hostResolvedURL = onlyHostURL?.appendingQueryParameters(queryParametes)
        XCTAssertNotNil(hostResolvedURL)
        XCTAssertEqual(hostResolvedURL!.absoluteString, "https://some.beautiful.cat?Another=With%20non-URL%20safe%20%2520%20value&Other%2520Key=And%20value%20%26%20as%20non-URL%20Safe?&Some=Valid")
        
        let hostAndQueryResolvedURL = hostAndQueryURL?.appendingQueryParameters(queryParametes)
        XCTAssertNotNil(hostAndQueryResolvedURL)
        XCTAssertEqual(hostAndQueryResolvedURL!.absoluteString, "https://some.beautiful.cat?at=window&Another=With%20non-URL%20safe%20%2520%20value&Other%2520Key=And%20value%20%26%20as%20non-URL%20Safe?&Some=Valid")
    }

}
