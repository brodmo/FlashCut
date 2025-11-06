//
//  String.swift
//
//  Created by Wojciech Kulik on 13/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation

extension String {
    static let defaultIconSymbol = "bolt.fill"

    func padEnd(toLength length: Int, withPad pad: String = " ") -> String {
        if count < length {
            return self + String(repeating: pad, count: length - count)
        } else {
            return self
        }
    }
}
