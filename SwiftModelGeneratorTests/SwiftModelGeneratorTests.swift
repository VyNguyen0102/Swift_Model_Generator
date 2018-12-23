//
//  SwiftModelGeneratorTests.swift
//  SwiftModelGeneratorTests
//
//  Created by Vy Nguyen on 11/26/18.
//  Copyright © 2018 VVLab. All rights reserved.
//

import XCTest
@testable import SwiftModelGenerator

class SwiftModelGeneratorTests: XCTestCase {
    var sampleStruct = StructModel.init(structName: "StructModel")
    var sampleString = "{\"widget\": {"
    + "\"debug\": \"on\","
    + "\"window\": {"
    + "\"title\": \"Sample Konfabulator Widget\","
    + "\"name\": \"main_window\","
    + "\"width\": 500,"
    + "\"height\": 500"
    + "},"
    + "\"image\": {"
    + "\"src\": \"Images/Sun.png\","
    + "\"name\": \"sun1\","
    + "\"hOffset\": 250,"
    + "\"vOffset\": 250,"
    + "\"alignment\": \"center\""
    + "},"
    + "\"text\": {"

    + "\"data\": \"Click Here\","
    + "\"size\": 36,"
    + "\"style\": \"bold\","
    + "\"name\": \"text1\","
    + "\"hOffset\": 250,"
    + "\"vOffset\": 100,"
    + "\"alignment\": \"center\","
    + "\"onMouseUp\": \"sun1.opacity = (sun1.opacity / 100) * 90;\""
    + "}"
    + "}}  "
    override func setUp() {
        sampleStruct.variables["MeoMeo"] = DataType.bool
        sampleStruct.variables["MeoMeo"] = DataType.string
        sampleStruct.variables["MeoMeo"] = DataType.typeStruct(structName: "HeoHeo")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        print(sampleStruct.toString())
    }

    func testJson() {
        guard let dic = sampleString.dictionary else {
            return
        }
        dic.forEach { (key, value) in
            
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
