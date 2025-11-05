//
//  WorkspaceHotKeys.swift
//
//  Created by Wojciech Kulik on 08/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

final class WorkspaceHotKeys {
    private let workspaceManager: WorkspaceManager
    private let workspaceRepository: WorkspaceRepository
    private let workspaceSettings: WorkspaceSettings

    init(
        workspaceManager: WorkspaceManager,
        workspaceRepository: WorkspaceRepository,
        settingsRepository: SettingsRepository
    ) {
        self.workspaceManager = workspaceManager
        self.workspaceRepository = workspaceRepository
        self.workspaceSettings = settingsRepository.workspaceSettings
    }

    func getHotKeys() -> [(AppHotKey, () -> ())] {
        let hotKeys = [
            getRecentWorkspaceHotKey(),
            getCycleWorkspacesHotKey(next: false),
            getCycleWorkspacesHotKey(next: true)
        ] +
            workspaceRepository.workspaces
            .flatMap { [getActivateHotKey(for: $0), getAssignAppHotKey(for: $0)] }

        return hotKeys.compactMap(\.self)
    }

    private func getActivateHotKey(for workspace: Workspace) -> (AppHotKey, () -> ())? {
        guard let shortcut = workspace.activateShortcut else { return nil }

        let action = { [weak self] in
            guard let self, let updatedWorkspace = workspaceRepository.findWorkspace(with: workspace.id) else { return }

            // Show toast if there are no running apps and we won't auto-launch them
            if !updatedWorkspace.hasRunningApps,
               workspace.apps.isEmpty || updatedWorkspace.openAppsOnActivation != true {
                Toast.showWith(
                    icon: "square.stack.3d.up",
                    message: "\(workspace.name) - No Running Apps To Show",
                    textColor: .gray
                )
                return
            }

            workspaceManager.activateWorkspace(updatedWorkspace, setFocus: true)
        }

        return (shortcut, action)
    }

    private func getAssignAppHotKey(for workspace: Workspace) -> (AppHotKey, () -> ())? {
        guard let shortcut = workspace.assignAppShortcut else { return nil }

        return (shortcut, { [weak self] in self?.assignApp(to: workspace) })
    }

    private func getCycleWorkspacesHotKey(next: Bool) -> (AppHotKey, () -> ())? {
        guard let shortcut = next
            ? workspaceSettings.switchToNextWorkspace
            : workspaceSettings.switchToPreviousWorkspace
        else { return nil }

        let action: () -> () = { [weak self] in
            guard let self else { return }

            workspaceManager.activateWorkspace(
                next: next,
                loop: workspaceSettings.loopWorkspaces
            )
        }

        return (shortcut, action)
    }

    private func getRecentWorkspaceHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = workspaceSettings.switchToRecentWorkspace else { return nil }

        let action: () -> () = { [weak self] in
            self?.workspaceManager.activateRecentWorkspace()
        }

        return (shortcut, action)
    }
}

extension WorkspaceHotKeys {
    private func assignApp(to workspace: Workspace) {
        guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
        guard let appName = activeApp.localizedName else { return }
        guard activeApp.activationPolicy == .regular else {
            Alert.showOkAlert(
                title: appName,
                message: "This application is an agent (runs in background) and cannot be managed by FlashCut."
            )
            return
        }

        guard let updatedWorkspace = workspaceRepository.findWorkspace(with: workspace.id) else { return }

        workspaceManager.assignApp(activeApp.toMacApp, to: updatedWorkspace)

        Toast.showWith(
            icon: "square.stack.3d.up",
            message: "\(appName) - Assigned To \(workspace.name)",
            textColor: .positive
        )
    }
}
