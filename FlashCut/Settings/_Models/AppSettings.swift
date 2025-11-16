struct AppSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case checkForUpdatesAutomatically
        case showFlashCut
        case recentAppGroup
        case nextAppInGroup
        case previousAppInGroup
    }

    // General
    var checkForUpdatesAutomatically: Bool?
    var showFlashCut: AppHotKey?

    // App Groups
    var recentAppGroup: AppHotKey?
    var nextAppInGroup: AppHotKey?
    var previousAppInGroup: AppHotKey?
}
