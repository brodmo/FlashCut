import Combine
import Foundation

final class SettingsRepository: ObservableObject {
    private(set) var generalSettings: GeneralSettings
    private(set) var appGroupSettings: AppGroupSettings
    private(set) var appGroupRepository: AppGroupRepository?

    private lazy var allSettings: [SettingsProtocol] = [
        generalSettings,
        appGroupSettings
    ]

    private var currentSettings = AppSettings()
    private var cancellables = Set<AnyCancellable>()
    private var shouldUpdate = false

    init(
        generalSettings: GeneralSettings,
        appGroupSettings: AppGroupSettings
    ) {
        self.generalSettings = generalSettings
        self.appGroupSettings = appGroupSettings

        loadFromDisk()

        Publishers.MergeMany(allSettings.map(\.updatePublisher))
            .sink { [weak self] in self?.updateSettings() }
            .store(in: &cancellables)
    }

    func setAppGroupRepository(_ repository: AppGroupRepository) {
        appGroupRepository = repository
        repository.appGroupsPublisher
            .sink { [weak self] _ in self?.updateSettings() }
            .store(in: &cancellables)
    }

    func saveToDisk() {
        Logger.log("Saving settings to disk")
        try? ConfigSerializer.serialize(filename: "config", currentSettings)
    }

    func getMinimalAppGroups() -> [MinimalAppGroup] {
        currentSettings.appGroups ?? []
    }

    private func updateSettings() {
        guard shouldUpdate else { return }

        var settings = AppSettings()
        allSettings.forEach { $0.update(&settings) }

        // Convert AppGroups to MinimalAppGroups for storage
        settings.appGroups = appGroupRepository?.appGroups.map { group in
            MinimalAppGroup(
                name: group.name,
                shortcut: group.shortcut,
                apps: group.apps.map(\.bundleIdentifier),
                target: group.targetApp?.bundleIdentifier
            )
        }

        currentSettings = settings
        saveToDisk()

        AppDependencies.shared.hotKeysManager.refresh()
        objectWillChange.send()
    }

    private func loadFromDisk() {
        Logger.log("Loading settings from disk")

        shouldUpdate = false
        defer { shouldUpdate = true }

        guard let settings = try? ConfigSerializer.deserialize(
            AppSettings.self,
            filename: "config"
        ) else { return }

        currentSettings = settings
        allSettings.forEach { $0.load(from: settings) }
    }
}
