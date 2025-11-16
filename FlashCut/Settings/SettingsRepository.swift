import Combine
import Foundation

final class SettingsRepository: ObservableObject {
    private(set) var generalSettings: GeneralSettings
    private(set) var appGroupSettings: AppGroupSettings

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

    func saveToDisk() {
        Logger.log("Saving settings to disk")
        try? ConfigSerializer.serialize(filename: "settings", currentSettings)
    }

    private func updateSettings() {
        guard shouldUpdate else { return }

        var settings = AppSettings()
        allSettings.forEach { $0.update(&settings) }
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
            filename: "settings"
        ) else { return }

        currentSettings = settings
        allSettings.forEach { $0.load(from: settings) }
    }
}
