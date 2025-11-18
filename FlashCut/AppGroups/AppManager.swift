import AppKit

final class AppManager {
    var currentApp: NSRunningApplication? { NSWorkspace.shared.frontmostApplication }

    private let appGroupRepository: AppGroupRepository
    private let appGroupManager: AppGroupManager

    init(
        appGroupRepository: AppGroupRepository,
        appGroupManager: AppGroupManager
    ) {
        self.appGroupRepository = appGroupRepository
        self.appGroupManager = appGroupManager
    }

    /// Cycles to the next running app within the current app's group.
    ///
    /// Automatically detects which group the frontmost app belongs to,
    /// then activates the next running app in that group. Wraps around
    /// to the beginning of the list after reaching the last app.
    ///
    /// Does nothing if the current app is not in any group or if there
    /// are no other running apps in the group.
    func cycleAppsInGroup() {
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
