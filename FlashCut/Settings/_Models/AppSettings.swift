struct AppSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case checkForUpdatesAutomatically
        case recentAppGroup
        case nextAppInGroup
        case previousAppInGroup
    }

    // General
    var checkForUpdatesAutomatically: Bool?

    // App Groups
    var recentAppGroup: AppHotKey?
    var nextAppInGroup: AppHotKey?
    var previousAppInGroup: AppHotKey?
}
