import AppKit

final class AppManager {
    var currentApp: NSRunningApplication? { NSWorkspace.shared.frontmostApplication }

    private let appGroupRepository: AppGroupRepository
    private let appGroupManager: AppGroupManager
    private let settings: Settings

    init(
        appGroupRepository: AppGroupRepository,
        appGroupManager: AppGroupManager,
        settings: Settings
    ) {
        self.appGroupRepository = appGroupRepository
        self.appGroupManager = appGroupManager
        self.settings = settings
    }

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
