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
            getAssignAppHotKey(for: nil),
            getUnassignAppHotKey(),
            getToggleAssignmentHotKey(),
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

    private func getAssignAppHotKey(for workspace: Workspace?) -> (AppHotKey, () -> ())? {
        let shortcut = workspace == nil
            ? workspaceSettings.assignFocusedApp
            : workspace?.assignAppShortcut

        guard let shortcut else { return nil }

        return (shortcut, { [weak self] in self?.assignApp(to: workspace) })
    }

    private func getUnassignAppHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = workspaceSettings.unassignFocusedApp else { return nil }

        return (shortcut, { [weak self] in self?.unassignApp() })
    }

    private func getToggleAssignmentHotKey() -> (AppHotKey, () -> ())? {
        guard let shortcut = workspaceSettings.toggleFocusedAppAssignment else { return nil }

        let action = { [weak self] in
            guard let self, let activeApp = NSWorkspace.shared.frontmostApplication else { return }

            if workspaceRepository.workspaces.flatMap(\.apps).containsApp(activeApp) {
                unassignApp()
            } else {
                assignApp(to: nil)
            }
        }

        return (shortcut, action)
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
}

extension WorkspaceHotKeys {
    private func assignApp(to workspace: Workspace?) {
        guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
        guard let appName = activeApp.localizedName else { return }
        guard activeApp.activationPolicy == .regular else {
            Alert.showOkAlert(
                title: appName,
                message: "This application is an agent (runs in background) and cannot be managed by FlashCut."
            )
            return
        }

        // If no specific workspace provided, find which workspace the app belongs to
        let targetWorkspace = workspace ?? workspaceRepository.workspaces.first { $0.apps.containsApp(activeApp) }

        guard let targetWorkspace else {
            Alert.showOkAlert(
                title: "Error",
                message: "Please use a workspace-specific assignment hotkey, or first add the app to a workspace."
            )
            return
        }

        guard let updatedWorkspace = workspaceRepository.findWorkspace(with: targetWorkspace.id) else { return }

        workspaceManager.assignApp(activeApp.toMacApp, to: updatedWorkspace)

        Toast.showWith(
            icon: "square.stack.3d.up",
            message: "\(appName) - Assigned To \(targetWorkspace.name)",
            textColor: .positive
        )
    }

    private func unassignApp() {
        guard let activeApp = NSWorkspace.shared.frontmostApplication else { return }
        guard let appName = activeApp.localizedName else { return }

        if workspaceRepository.workspaces.flatMap(\.apps).containsApp(activeApp) == true {
            Toast.showWith(
                icon: "square.stack.3d.up.slash",
                message: "\(appName) - Removed From Workspaces",
                textColor: .negative
            )
        }

        workspaceRepository.deleteAppFromAllWorkspaces(app: activeApp.toMacApp)
        NotificationCenter.default.post(name: .appsListChanged, object: nil)
    }
}
