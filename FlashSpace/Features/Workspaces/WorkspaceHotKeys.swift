//
//  AppGroupHotKeys.swift
//
//  Created by Wojciech Kulik on 08/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

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
        let hotKeys = [
            getRecentAppGroupHotKey(),
            getCycleAppGroupsHotKey(next: false),
            getCycleAppGroupsHotKey(next: true)
        ] +
            appGroupRepository.appGroups
            .compactMap { getActivateHotKey(for: $0) }

        return hotKeys.compactMap(\.self)
    }

    private func getActivateHotKey(for appGroup: AppGroup) -> (AppHotKey, () -> ())? {
        guard let shortcut = appGroup.activateShortcut else { return nil }

        let action = { [weak self] in
            guard let self, let updatedAppGroup = appGroupRepository.findAppGroup(with: appGroup.id) else { return }

            appGroupManager.activateAppGroup(updatedAppGroup, setFocus: true)
        }

        return (shortcut, action)
    }

    private func getCycleAppGroupsHotKey(next: Bool) -> (AppHotKey, () -> ())? {
        guard let shortcut = next
            ? appGroupSettings.switchToNextAppGroup
            : appGroupSettings.switchToPreviousAppGroup
        else { return nil }

        let action: () -> () = { [weak self] in
            guard let self else { return }

            appGroupManager.activateAppGroup(
                next: next,
                loop: appGroupSettings.loopAppGroups
            )
        }

        return (shortcut, action)
    }

    private func getRecentAppGroupHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = appGroupSettings.switchToRecentAppGroup else { return nil }

        let action: () -> () = { [weak self] in
            self?.appGroupManager.activateRecentAppGroup()
        }

        return (shortcut, action)
    }
}

// No assignment logic - users manage assignments via UI only
