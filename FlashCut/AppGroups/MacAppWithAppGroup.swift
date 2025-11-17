import Foundation
import SwiftUI

struct MacAppWithAppGroup: Hashable, Codable {
    var app: MacApp
    var appGroupId: UUID
}

extension MacAppWithAppGroup: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: MacAppWithAppGroup.self, contentType: .json)
    }
}
