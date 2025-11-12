import AppKit
import Foundation

typealias AppGroupID = UUID

struct AppGroup: Identifiable, Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case activateShortcut = "shortcut"
        case apps
        case targetApp = "target"
        case openAppsOnActivation
    }

    var id: AppGroupID
    var name: String
    var activateShortcut: AppHotKey?
    var apps: [MacApp]
    var targetApp: MacApp?
    var openAppsOnActivation: Bool?
}

extension AppGroup {
    /// Check if any apps from this appGroup are currently running
    var hasRunningApps: Bool {
        let runningBundleIds = NSWorkspace.shared.runningRegularApps
            .compactMap(\.bundleIdentifier)
            .asSet

        return apps.contains { runningBundleIds.contains($0.bundleIdentifier) }
    }
}
