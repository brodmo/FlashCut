import Foundation

@Observable
final class ConfigRepository {
    var settings: Settings
    private var minimalAppGroups: [MinimalAppGroup] = []
    private(set) var appGroupRepository: AppGroupRepository?

    init() {
        self.settings = Settings()
        Logger.log("Loading config from disk")
        guard let config = try? ConfigSerializer.deserialize(Config.self, filename: "config") else { return }
        settings.checkForUpdatesAutomatically = config.settings.checkForUpdatesAutomatically
        settings.lastAppGroup = config.settings.lastAppGroup
        settings.cycleAppsInGroup = config.settings.cycleAppsInGroup
        self.minimalAppGroups = config.appGroups
    }

    func setAppGroupRepository(_ repository: AppGroupRepository) {
        appGroupRepository = repository
    }

    func save() {
        Logger.log("Saving config to disk")

        let minimalAppGroups = appGroupRepository?.appGroups.map { MinimalAppGroup(from: $0) } ?? []

        let config = Config(
            settings: settings,
            appGroups: minimalAppGroups
        )

        try? ConfigSerializer.serialize(filename: "config", config)
        AppDependencies.shared.hotKeysManager.refresh()
    }

    func getMinimalAppGroups() -> [MinimalAppGroup] {
        minimalAppGroups
    }
}
