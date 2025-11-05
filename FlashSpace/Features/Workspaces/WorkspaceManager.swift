//
//  WorkspaceManager.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine

final class AppGroupManager: ObservableObject {
    // Minimal state for cycling and recent appGroup switching
    private var lastActivatedAppGroup: AppGroup?
    private var previousActivatedAppGroup: AppGroup?

    private var cancellables = Set<AnyCancellable>()

    private let appGroupRepository: AppGroupRepository
    private let appGroupSettings: AppGroupSettings

    init(
        appGroupRepository: AppGroupRepository,
        settingsRepository: SettingsRepository
    ) {
        self.appGroupRepository = appGroupRepository
        self.appGroupSettings = settingsRepository.appGroupSettings

        PermissionsManager.shared.askForAccessibilityPermissions()
    }

    private func findAppToFocus(in appGroup: AppGroup) -> NSRunningApplication? {
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { appGroup.apps.containsApp($0) }

        // If appGroup has a preferred app to focus, use that
        if let preferredApp = appGroup.appToFocus {
            if let app = runningApps.find(preferredApp) {
                return app
            }
        }

        // Otherwise just pick first running app from the group
        let fallbackApp = runningApps.findFirstMatch(with: appGroup.apps)
        let fallbackToFinder = NSWorkspace.shared.runningApplications.first(where: \.isFinder)

        return fallbackApp ?? fallbackToFinder
    }

    private func centerCursorIfNeeded(in frame: CGRect?) {
        guard appGroupSettings.centerCursorOnAppActivation, let frame else { return }

        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func openAppsIfNeeded(in appGroup: AppGroup) {
        guard appGroup.openAppsOnActivation == true else { return }

        let runningBundleIds = NSWorkspace.shared.runningApplications
            .compactMap(\.bundleIdentifier)
            .asSet

        appGroup.apps
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

// MARK: - AppGroup Actions
extension AppGroupManager {
    func activateAppGroup(_ appGroup: AppGroup, setFocus: Bool) {
        Logger.log("")
        Logger.log("")
        Logger.log("APP GROUP: \(appGroup.name)")
        Logger.log("----")

        // Track previous for recent appGroup switching
        if let last = lastActivatedAppGroup, last.id != appGroup.id {
            previousActivatedAppGroup = last
        }

        // Remember for cycling
        lastActivatedAppGroup = appGroup

        // Optionally launch apps in the group
        openAppsIfNeeded(in: appGroup)

        // Simply focus an app in the group if requested
        if setFocus {
            let toFocus = findAppToFocus(in: appGroup)
            Logger.log("FOCUS: \(toFocus?.localizedName ?? "none")")
            toFocus?.activate()
            centerCursorIfNeeded(in: toFocus?.frame)
        }
    }

    func activateAppGroup(next: Bool, loop: Bool) {
        let appGroups = appGroupRepository.appGroups

        guard let currentAppGroup = lastActivatedAppGroup ?? appGroups.first else {
            // No appGroup activated yet, activate first one
            if let first = appGroups.first {
                activateAppGroup(first, setFocus: true)
            }
            return
        }

        var appGroupsToLoop = next ? appGroups : appGroups.reversed()

        let nextAppGroups = appGroupsToLoop
            .drop(while: { $0.id != currentAppGroup.id })
            .dropFirst()

        let selectedAppGroup = nextAppGroups.first ?? (loop ? appGroupsToLoop.first : nil)

        guard let selectedAppGroup, selectedAppGroup.id != currentAppGroup.id else { return }

        activateAppGroup(selectedAppGroup, setFocus: true)
    }

    func activateRecentAppGroup() {
        // Alt+Tab-like behavior for app groups: switch to previous appGroup
        guard let previous = previousActivatedAppGroup else { return }
        guard let updatedAppGroup = appGroupRepository.findAppGroup(with: previous.id) else { return }

        activateAppGroup(updatedAppGroup, setFocus: true)
    }

    func activateAppGroupIfActive(_ appGroupId: AppGroupID) {
        // Simplified: just re-activate if it was the last one
        guard lastActivatedAppGroup?.id == appGroupId else { return }
        guard let updatedAppGroup = appGroupRepository.findAppGroup(with: appGroupId) else { return }

        activateAppGroup(updatedAppGroup, setFocus: false)
    }
}
