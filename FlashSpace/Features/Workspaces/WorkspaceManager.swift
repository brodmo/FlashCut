//
//  WorkspaceManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine

final class WorkspaceManager: ObservableObject {
    // Minimal state for cycling and recent workspace switching
    private var lastActivatedWorkspace: Workspace?
    private var previousActivatedWorkspace: Workspace?

    private var cancellables = Set<AnyCancellable>()

    private let workspaceRepository: WorkspaceRepository
    private let workspaceSettings: WorkspaceSettings

    init(
        workspaceRepository: WorkspaceRepository,
        settingsRepository: SettingsRepository
    ) {
        self.workspaceRepository = workspaceRepository
        self.workspaceSettings = settingsRepository.workspaceSettings

        PermissionsManager.shared.askForAccessibilityPermissions()
    }

    private func findAppToFocus(in workspace: Workspace) -> NSRunningApplication? {
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { workspace.apps.containsApp($0) }

        // If workspace has a preferred app to focus, use that
        if let preferredApp = workspace.appToFocus {
            if let app = runningApps.find(preferredApp) {
                return app
            }
        }

        // Otherwise just pick first running app from the group
        let fallbackApp = runningApps.findFirstMatch(with: workspace.apps)
        let fallbackToFinder = NSWorkspace.shared.runningApplications.first(where: \.isFinder)

        return fallbackApp ?? fallbackToFinder
    }

    private func centerCursorIfNeeded(in frame: CGRect?) {
        guard workspaceSettings.centerCursorOnAppActivation, let frame else { return }

        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func openAppsIfNeeded(in workspace: Workspace) {
        guard workspace.openAppsOnActivation == true else { return }

        let runningBundleIds = NSWorkspace.shared.runningApplications
            .compactMap(\.bundleIdentifier)
            .asSet

        workspace.apps
            .filter { !runningBundleIds.contains($0.bundleIdentifier) }
            .compactMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0.bundleIdentifier) }
            .forEach { appUrl in
                Logger.log("Open App: \(appUrl)")

                let config = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.openApplication(at: appUrl, configuration: config) { _, error in
                    if let error {
                        Logger.log("Failed to open \(appUrl): \(error.localizedDescription)")
                    }
                }
            }
    }
}

// MARK: - Workspace Actions
extension WorkspaceManager {
    func activateWorkspace(_ workspace: Workspace, setFocus: Bool) {
        Logger.log("")
        Logger.log("")
        Logger.log("APP GROUP: \(workspace.name)")
        Logger.log("----")

        // Track previous for recent workspace switching
        if let last = lastActivatedWorkspace, last.id != workspace.id {
            previousActivatedWorkspace = last
        }

        // Remember for cycling
        lastActivatedWorkspace = workspace

        // Optionally launch apps in the group
        openAppsIfNeeded(in: workspace)

        // Simply focus an app in the group if requested
        if setFocus {
            let toFocus = findAppToFocus(in: workspace)
            Logger.log("FOCUS: \(toFocus?.localizedName ?? "none")")
            toFocus?.activate()
            centerCursorIfNeeded(in: toFocus?.frame)
        }
    }

    func assignApp(_ app: MacApp, to workspace: Workspace) {
        workspaceRepository.deleteAppFromAllWorkspaces(app: app)
        workspaceRepository.addApp(to: workspace.id, app: app)

        guard let targetWorkspace = workspaceRepository.findWorkspace(with: workspace.id) else { return }

        // Just focus the next app in the workspace
        AppDependencies.shared.focusManager.nextWorkspaceApp()

        NotificationCenter.default.post(name: .appsListChanged, object: nil)
    }

    func activateWorkspace(next: Bool, loop: Bool) {
        let workspaces = workspaceRepository.workspaces

        guard let currentWorkspace = lastActivatedWorkspace ?? workspaces.first else {
            // No workspace activated yet, activate first one
            if let first = workspaces.first {
                activateWorkspace(first, setFocus: true)
            }
            return
        }

        var workspacesToLoop = next ? workspaces : workspaces.reversed()

        let nextWorkspaces = workspacesToLoop
            .drop(while: { $0.id != currentWorkspace.id })
            .dropFirst()

        let selectedWorkspace = nextWorkspaces.first ?? (loop ? workspacesToLoop.first : nil)

        guard let selectedWorkspace, selectedWorkspace.id != currentWorkspace.id else { return }

        activateWorkspace(selectedWorkspace, setFocus: true)
    }

    func activateRecentWorkspace() {
        // Alt+Tab-like behavior for app groups: switch to previous workspace
        guard let previous = previousActivatedWorkspace else { return }
        guard let updatedWorkspace = workspaceRepository.findWorkspace(with: previous.id) else { return }

        activateWorkspace(updatedWorkspace, setFocus: true)
    }

    func activateWorkspaceIfActive(_ workspaceId: WorkspaceID) {
        // Simplified: just re-activate if it was the last one
        guard lastActivatedWorkspace?.id == workspaceId else { return }
        guard let updatedWorkspace = workspaceRepository.findWorkspace(with: workspaceId) else { return }

        activateWorkspace(updatedWorkspace, setFocus: false)
    }
}
