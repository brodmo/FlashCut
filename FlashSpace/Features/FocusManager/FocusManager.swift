//
//  FocusManager.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

final class FocusManager {
    var visibleApps: [NSRunningApplication] {
        NSWorkspace.shared.runningRegularApps.filter { !$0.isHidden }
    }

    var focusedApp: NSRunningApplication? { NSWorkspace.shared.frontmostApplication }
    var focusedAppFrame: CGRect? { focusedApp?.frame }

    private let appGroupRepository: AppGroupRepository
    private let appGroupManager: AppGroupManager
    private let settings: FocusManagerSettings

    init(
        appGroupRepository: AppGroupRepository,
        appGroupManager: AppGroupManager,
        focusManagerSettings: FocusManagerSettings
    ) {
        self.appGroupRepository = appGroupRepository
        self.appGroupManager = appGroupManager
        self.settings = focusManagerSettings
    }

    func getHotKeys() -> [(AppHotKey, () -> ())] {
        return [
            settings.focusNextAppGroupApp.flatMap { ($0, nextAppGroupApp) },
            settings.focusPreviousAppGroupApp.flatMap { ($0, previousAppGroupApp) },
            settings.focusNextAppGroupWindow.flatMap { ($0, nextAppGroupWindow) },
            settings.focusPreviousAppGroupWindow.flatMap { ($0, previousAppGroupWindow) }
        ].compactMap { $0 }
    }

    func nextAppGroupWindow() {
        guard let focusedApp else { return nextAppGroupApp() }
        guard let (_, apps) = getFocusedAppIndex() else { return }

        let runningAppGroupApps = getRunningAppsWithSortedWindows(apps: apps)
        let focusedAppWindows = runningAppGroupApps
            .first { $0.bundleIdentifier == focusedApp.bundleIdentifier }?
            .windows ?? []
        let isLastWindowFocused = focusedAppWindows.last?.axWindow.isMain == true

        if isLastWindowFocused {
            let nextApps = runningAppGroupApps.drop(while: { $0.bundleIdentifier != focusedApp.bundleIdentifier }).dropFirst() +
                runningAppGroupApps.prefix(while: { $0.bundleIdentifier != focusedApp.bundleIdentifier })
            let nextApp = nextApps.first ?? MacAppWithWindows(app: focusedApp)

            nextApp.app.activate()
            nextApp
                .windows
                .first?
                .axWindow
                .focus()
        } else {
            focusedAppWindows
                .drop(while: { !$0.axWindow.isMain })
                .dropFirst()
                .first?
                .axWindow
                .focus()
        }
    }

    func previousAppGroupWindow() {
        guard let focusedApp else { return previousAppGroupApp() }
        guard let (_, apps) = getFocusedAppIndex() else { return }

        let runningAppGroupApps = getRunningAppsWithSortedWindows(apps: apps)
        let focusedAppWindows = runningAppGroupApps
            .first { $0.bundleIdentifier == focusedApp.bundleIdentifier }?
            .windows ?? []
        let isFirstWindowFocused = focusedAppWindows.first?.axWindow.isMain == true

        if isFirstWindowFocused {
            let prevApps = runningAppGroupApps.drop(while: { $0.bundleIdentifier != focusedApp.bundleIdentifier }).dropFirst() +
                runningAppGroupApps.prefix(while: { $0.bundleIdentifier != focusedApp.bundleIdentifier })
            let prevApp = prevApps.last ?? MacAppWithWindows(app: focusedApp)

            prevApp.app.activate()
            prevApp
                .windows
                .last?
                .axWindow
                .focus()
        } else {
            focusedAppWindows
                .prefix(while: { !$0.axWindow.isMain })
                .last?
                .axWindow
                .focus()
        }
    }

    func nextAppGroupApp() {
        guard let (index, apps) = getFocusedAppIndex() else { return }

        let appsQueue = apps.dropFirst(index + 1) + apps.prefix(index)
        let runningApps = NSWorkspace.shared.runningApplications
            .compactMap(\.bundleIdentifier)
            .asSet
        let nextApp = appsQueue.first { app in runningApps.contains(app.bundleIdentifier) }

        NSWorkspace.shared.runningApplications
            .find(nextApp)?
            .activate()
    }

    func previousAppGroupApp() {
        guard let (index, apps) = getFocusedAppIndex() else { return }

        let runningApps = NSWorkspace.shared.runningApplications
            .compactMap(\.bundleIdentifier)
            .asSet
        let prefixApps = apps.prefix(index).reversed()
        let suffixApps = apps.suffix(apps.count - index - 1).reversed()
        let appsQueue = prefixApps + Array(suffixApps)
        let previousApp = appsQueue.first { app in runningApps.contains(app.bundleIdentifier) }

        NSWorkspace.shared.runningApplications
            .find(previousApp)?
            .activate()
    }

    private func getFocusedAppIndex() -> (Int, [MacApp])? {
        guard let focusedApp else { return nil }

        // Find appGroup containing the focused app (stateless approach)
        let appGroup = appGroupRepository.appGroups.first { $0.apps.containsApp(focusedApp) }

        guard let appGroup else { return nil }

        let apps = appGroup.apps

        let index = apps.firstIndex(of: focusedApp) ?? 0

        return (index, apps)
    }

    private func getRunningAppsWithSortedWindows(apps: [MacApp]) -> [MacAppWithWindows] {
        let order = apps
            .enumerated()
            .reduce(into: [String: Int]()) {
                $0[$1.element.bundleIdentifier] = $1.offset
            }

        return NSWorkspace.shared.runningApplications
            .filter { !$0.isHidden && apps.containsApp($0) }
            .map { MacAppWithWindows(app: $0) }
            .sorted { order[$0.bundleIdentifier] ?? 0 < order[$1.bundleIdentifier] ?? 0 }
    }
}
