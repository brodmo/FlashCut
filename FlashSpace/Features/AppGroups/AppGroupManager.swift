//
//  AppGroupManager.swift
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

    // Track recently activated apps to find most recent when activating a group
    private var recentlyActivatedApps: [String: Date] = [:] // bundleIdentifier -> timestamp

    private var cancellables = Set<AnyCancellable>()

    private let appGroupRepository: AppGroupRepository
    private let appGroupSettings: AppGroupSettings

    init(
        appGroupRepository: AppGroupRepository,
        settingsRepository: SettingsRepository
    ) {
        self.appGroupRepository = appGroupRepository
        self.appGroupSettings = settingsRepository.appGroupSettings

        // Track app activations to find most recently used app in a group
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppActivation),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }

        recentlyActivatedApps[bundleId] = Date()
    }

    private func findApp(in appGroup: AppGroup) -> NSRunningApplication? {
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { appGroup.apps.containsApp($0) }

        // If appGroup has a preferred target app, use that
        if let preferredApp = appGroup.targetApp {
            if let app = runningApps.find(preferredApp) {
                return app
            }
        }

        // Otherwise find the most recently activated app from the group
        return runningApps
            .max(by: { app1, app2 in
                let time1 = app1.bundleIdentifier.flatMap { recentlyActivatedApps[$0] } ?? .distantPast
                let time2 = app2.bundleIdentifier.flatMap { recentlyActivatedApps[$0] } ?? .distantPast
                return time1 < time2
            })
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

        // Simply activate an app in the group if requested
        if setFocus {
            let appToActivate = findApp(in: appGroup)
            Logger.log("ACTIVATE: \(appToActivate?.localizedName ?? "none")")
            appToActivate?.activate()
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

        let appGroupsToLoop = next ? appGroups : appGroups.reversed()

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
