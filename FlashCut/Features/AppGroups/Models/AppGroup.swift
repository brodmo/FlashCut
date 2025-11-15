import AppKit
import Foundation

typealias AppGroupID = UUID

@Observable
class AppGroup: Identifiable, Codable, Hashable {
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

    init(
        id: AppGroupID = UUID(),
        name: String,
        activateShortcut: AppHotKey? = nil,
        apps: [MacApp] = [],
        targetApp: MacApp? = nil,
        openAppsOnActivation: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.activateShortcut = activateShortcut
        self.apps = apps
        self.targetApp = targetApp
        self.openAppsOnActivation = openAppsOnActivation
    }

    // MARK: - Hashable

    static func == (lhs: AppGroup, rhs: AppGroup) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Codable

    // Manual implementation required due to @Observable macro

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(AppGroupID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.activateShortcut = try container.decodeIfPresent(AppHotKey.self, forKey: .activateShortcut)
        self.apps = try container.decode([MacApp].self, forKey: .apps)
        self.targetApp = try container.decodeIfPresent(MacApp.self, forKey: .targetApp)
        self.openAppsOnActivation = try container.decodeIfPresent(Bool.self, forKey: .openAppsOnActivation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(activateShortcut, forKey: .activateShortcut)
        try container.encode(apps, forKey: .apps)
        try container.encodeIfPresent(targetApp, forKey: .targetApp)
        try container.encodeIfPresent(openAppsOnActivation, forKey: .openAppsOnActivation)
    }
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
