import AppKit
import Foundation

typealias AppGroupID = UUID

@Observable
class AppGroup: Identifiable, Hashable {
    var id: AppGroupID
    var name: String
    var shortcut: AppHotKey?
    var apps: [MacApp]
    var targetApp: MacApp?

    init(
        id: AppGroupID = UUID(),
        name: String,
        shortcut: AppHotKey? = nil,
        apps: [MacApp] = [],
        targetApp: MacApp? = nil
    ) {
        self.id = id
        self.name = name
        self.shortcut = shortcut
        self.apps = apps
        self.targetApp = targetApp
    }

    // MARK: - Hashable

    static func == (lhs: AppGroup, rhs: AppGroup) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
