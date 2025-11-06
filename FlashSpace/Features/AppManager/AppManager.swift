//
//  AppManager.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Foundation

final class AppManager {
    var currentApp: NSRunningApplication? { NSWorkspace.shared.frontmostApplication }

    private let appGroupRepository: AppGroupRepository
    private let appGroupManager: AppGroupManager
    private let settings: AppManagerSettings

    init(
        appGroupRepository: AppGroupRepository,
        appGroupManager: AppGroupManager,
        appManagerSettings: AppManagerSettings
    ) {
        self.appGroupRepository = appGroupRepository
        self.appGroupManager = appGroupManager
        self.settings = appManagerSettings
    }

    func getHotKeys() -> [(AppHotKey, () -> ())] {
        [
            settings.switchToNextAppInGroup.flatMap { ($0, nextAppGroupApp) },
            settings.switchToPreviousAppInGroup.flatMap { ($0, previousAppGroupApp) }
        ].compactMap { $0 }
    }

    func nextAppGroupApp() {
        guard let (index, apps) = getCurrentAppIndex() else { return }

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
        guard let (index, apps) = getCurrentAppIndex() else { return }

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

    private func getCurrentAppIndex() -> (Int, [MacApp])? {
        guard let currentApp else { return nil }

        // Find appGroup containing the current app (stateless approach)
        let appGroup = appGroupRepository.appGroups.first { $0.apps.containsApp(currentApp) }

        guard let appGroup else { return nil }

        let apps = appGroup.apps

        let index = apps.firstIndex(of: currentApp) ?? 0

        return (index, apps)
    }
}
