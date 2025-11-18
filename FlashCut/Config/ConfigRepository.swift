import Foundation

@Observable
final class ConfigRepository {
    private(set) var config: Config

    init() {
        if let loadedConfig = try? ConfigSerializer.deserialize(Config.self, filename: "config") {
            self.config = loadedConfig
            Logger.log("Config loaded from disk")
        } else {
            self.config = Config()
            Logger.log("No config found, created a new one.")
        }
        UpdatesManager.shared.updaterController.updater.automaticallyChecksForUpdates = config.settings.checkForUpdatesAutomatically
    }

    private func save() {
        Logger.log("Saving config to disk")
        do {
            try ConfigSerializer.serialize(filename: "config", config)
        } catch {
            Logger.log("Failed to save config: \(error)")
        }
        AppDependencies.shared.hotKeysManager.refresh()
    }

    // MARK: - Settings API

    func setCheckForUpdatesAutomatically(to value: Bool) {
        config.settings.checkForUpdatesAutomatically = value
        UpdatesManager.shared.updaterController.updater.automaticallyChecksForUpdates = value
        save()
    }

    func setLastAppGroup(to value: AppHotKey?) {
        config.settings.lastAppGroup = value
        save()
    }

    func setCycleAppsInGroup(to value: AppHotKey?) {
        config.settings.cycleAppsInGroup = value
        save()
    }

    func updateAppGroups(_ appGroups: [AppGroup]) {
        config.appGroups = appGroups.map { MinimalAppGroup(from: $0) }
        save()
    }
}
