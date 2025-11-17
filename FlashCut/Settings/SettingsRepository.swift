import Combine
import Foundation

final class SettingsRepository: ObservableObject {
    private(set) var settings: Settings
    private(set) var appGroupRepository: AppGroupRepository?

    private var currentConfig = Config()
    private var cancellables = Set<AnyCancellable>()
    private var shouldUpdate = false

    init(settings: Settings) {
        self.settings = settings

        loadFromDisk()

        settings.updatePublisher
            .sink { [weak self] in self?.updateConfig() }
            .store(in: &cancellables)
    }

    func setAppGroupRepository(_ repository: AppGroupRepository) {
        appGroupRepository = repository
        repository.appGroupsPublisher
            .sink { [weak self] _ in self?.updateConfig() }
            .store(in: &cancellables)
    }

    func saveToDisk() {
        Logger.log("Saving settings to disk")
        try? ConfigSerializer.serialize(filename: "config", currentConfig)
    }

    func getMinimalAppGroups() -> [MinimalAppGroup] {
        currentConfig.appGroups ?? []
    }

    private func updateConfig() {
        guard shouldUpdate else { return }

        var config = Config()
        settings.update(&config)

        // Convert AppGroups to MinimalAppGroups for storage
        config.appGroups = appGroupRepository?.appGroups.map { group in
            MinimalAppGroup(
                name: group.name,
                shortcut: group.shortcut,
                apps: group.apps.map(\.bundleIdentifier),
                target: group.targetApp?.bundleIdentifier
            )
        }

        currentConfig = config
        saveToDisk()

        AppDependencies.shared.hotKeysManager.refresh()
        objectWillChange.send()
    }

    private func loadFromDisk() {
        Logger.log("Loading settings from disk")

        shouldUpdate = false
        defer { shouldUpdate = true }

        guard let config = try? ConfigSerializer.deserialize(
            Config.self,
            filename: "config"
        ) else { return }

        currentConfig = config
        settings.load(from: config)
    }
}
