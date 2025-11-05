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
        [
            settings.focusNextAppGroupApp.flatMap { ($0, nextAppGroupApp) },
            settings.focusPreviousAppGroupApp.flatMap { ($0, previousAppGroupApp) }
        ].compactMap { $0 }
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
}
