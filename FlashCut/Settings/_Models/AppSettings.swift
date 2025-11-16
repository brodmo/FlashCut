struct MinimalAppGroup: Codable {
    var name: String
    var shortcut: AppHotKey?
    var apps: [String]
    var target: String?
}

struct AppSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case checkForUpdatesAutomatically
        case recentAppGroup
        case nextAppInGroup
        case previousAppInGroup
        case appGroups
    }

    // General
    var checkForUpdatesAutomatically: Bool?

    // App Groups
    var recentAppGroup: AppHotKey?
    var nextAppInGroup: AppHotKey?
    var previousAppInGroup: AppHotKey?
    var appGroups: [MinimalAppGroup]?
}
