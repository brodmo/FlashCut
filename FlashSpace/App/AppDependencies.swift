//
//  AppDependencies.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import ShortcutRecorder

struct AppDependencies {
    static let shared = AppDependencies()

    let workspaceRepository: WorkspaceRepository
    let workspaceManager: WorkspaceManager
    let workspaceHotKeys: WorkspaceHotKeys

    let hotKeysMonitor: HotKeysMonitorProtocol = GlobalShortcutMonitor.shared
    let hotKeysManager: HotKeysManager

    let focusManager: FocusManager

    let settingsRepository: SettingsRepository
    let generalSettings = GeneralSettings()
    let focusManagerSettings = FocusManagerSettings()
    let workspaceSettings = WorkspaceSettings()

    let autostartService = AutostartService()

    private init() {
        self.settingsRepository = SettingsRepository(
            generalSettings: generalSettings,
            focusManagerSettings: focusManagerSettings,
            workspaceSettings: workspaceSettings
        )
        self.workspaceRepository = WorkspaceRepository()
        self.workspaceManager = WorkspaceManager(
            workspaceRepository: workspaceRepository,
            settingsRepository: settingsRepository
        )
        self.workspaceHotKeys = WorkspaceHotKeys(
            workspaceManager: workspaceManager,
            workspaceRepository: workspaceRepository,
            settingsRepository: settingsRepository
        )
        self.focusManager = FocusManager(
            workspaceRepository: workspaceRepository,
            workspaceManager: workspaceManager,
            focusManagerSettings: focusManagerSettings
        )
        self.hotKeysManager = HotKeysManager(
            hotKeysMonitor: GlobalShortcutMonitor.shared,
            workspaceHotKeys: workspaceHotKeys,
            focusManager: focusManager,
            settingsRepository: settingsRepository
        )

        Migrations.migrateIfNeeded(
            settingsRepository: settingsRepository
        )
    }
}
