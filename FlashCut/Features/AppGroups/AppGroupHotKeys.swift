import AppKit

final class AppGroupHotKeys {
    private let appGroupManager: AppGroupManager
    private let appGroupRepository: AppGroupRepository
    private let appGroupSettings: AppGroupSettings

    init(
        appGroupManager: AppGroupManager,
        appGroupRepository: AppGroupRepository,
        settingsRepository: SettingsRepository
    ) {
        self.appGroupManager = appGroupManager
        self.appGroupRepository = appGroupRepository
        self.appGroupSettings = settingsRepository.appGroupSettings
    }

    func getHotKeys() -> [(AppHotKey, () -> ())] {
        let hotKeys = [getRecentAppGroupHotKey()] +
            appGroupRepository.appGroups
            .compactMap { getOpenHotKey(for: $0) }

        return hotKeys.compactMap(\.self)
    }

    private func getOpenHotKey(for appGroup: AppGroup) -> (AppHotKey, () -> ())? {
        guard let shortcut = appGroup.shortcut else { return nil }

        let action = { [weak self] in
            guard let self, let updatedAppGroup = appGroupRepository.findAppGroup(with: appGroup.id) else { return }

            appGroupManager.openAppGroup(updatedAppGroup)
        }

        return (shortcut, action)
    }

    private func getRecentAppGroupHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = appGroupSettings.recentAppGroup else { return nil }

        let action: () -> () = { [weak self] in
            self?.appGroupManager.openRecentAppGroup()
        }

        return (shortcut, action)
    }
}

// No assignment logic - users manage assignments via UI only
