//
//  MacAppWithAppGroup.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation
import SwiftUI

struct MacAppWithAppGroup: Hashable, Codable {
    var app: MacApp
    var appGroupId: AppGroupID
}

extension MacAppWithAppGroup: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: MacAppWithAppGroup.self, contentType: .json)
    }
}
