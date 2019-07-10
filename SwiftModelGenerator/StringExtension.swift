//
//  StringExtension.swift
//  SwiftModelGenerator
//
//  Created by iOS Dev on 7/9/19.
//  Copyright © 2019 VVLab. All rights reserved.
//

import Foundation

extension String {
    static func createBlankBy(text: String, numberOfMaxBlankSpace: Int) -> String {
        if text.count >= numberOfMaxBlankSpace {
            return " "
        }
        let numberOfBlankSpace = numberOfMaxBlankSpace - text.count
        return String(repeating: " ", count: numberOfBlankSpace)
    }
}
