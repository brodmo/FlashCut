import AppKit
import Combine

final class AppGroupManager: ObservableObject {
    // Minimal state for cycling and recent appGroup switching
    private var lastAppGroup: AppGroup?
    private var previousAppGroup: AppGroup?

    // Track recently opened apps to find most recent when opening a group
    private var recentApps: [String: Date] = [:] // bundleIdentifier -> timestamp

    private let appGroupRepository: AppGroupRepository

    init(appGroupRepository: AppGroupRepository) {
        self.appGroupRepository = appGroupRepository

        // Track app opens to find most recently used app in a group
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppOpen),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func handleAppOpen(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }

        recentApps[bundleId] = Date()
    }

    private func findApp(in appGroup: AppGroup) {
        // Determine which app to launch: target app or most recently opened
        let appToLaunch = appGroup.targetApp ?? appGroup.apps
            .max(by: { app1, app2 in
                let time1 = recentApps[app1.bundleIdentifier] ?? .distantPast
                let time2 = recentApps[app2.bundleIdentifier] ?? .distantPast
                return time1 < time2
            })

        if let appToLaunch {
            launchApp(appToLaunch)
        }
    }

    private func launchApp(_ app: MacApp) {
        guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) else {
            Logger.log("Failed to find app URL for: \(app.name)")
            return
        }

        Logger.log("Launching primary app: \(app.name)")

        // Note: OpenConfiguration activates by default (brings app to foreground)
        NSWorkspace.shared.openApplication(at: appUrl, configuration: .init()) { app, error in
            if let error {
                Logger.log("Failed to launch \(app?.localizedName ?? "app"): \(error.localizedDescription)")
            } else if let app {
                Logger.log("Successfully launched and opened: \(app.localizedName ?? "app")")
            }
        }
    }
}

// MARK: - AppGroup Actions
extension AppGroupManager {
    /// Opens the specified app group by activating one of its apps.
    ///
    /// If the group has a target app configured, that app is activated.
    /// Otherwise, the most recently used app from the group is activated.
    /// This method also tracks group history for Alt+Tab-like switching.
    ///
    /// - Parameter appGroup: The app group to open
    func openAppGroup(_ appGroup: AppGroup) {
        Logger.log("")
        Logger.log("")
        Logger.log("APP GROUP: \(appGroup.name)")
        Logger.log("----")

        // Track previous for recent appGroup switching
        if let last = lastAppGroup, last.id != appGroup.id {
            previousAppGroup = last
        }

        // Remember for cycling
        lastAppGroup = appGroup

        // Launch an app in the group
        findApp(in: appGroup)
    }

    /// Switches to the previously active app group (Alt+Tab-like behavior).
    ///
    /// This method activates the app group that was active before the current one,
    /// enabling quick switching between two groups. Does nothing if there is no
    /// previous group or if the previous group no longer exists.
    func openLastAppGroup() {
        // Alt+Tab-like behavior for app groups: switch to previous appGroup
        guard let previous = previousAppGroup else { return }
        // Verify the appGroup still exists in the repository
        guard appGroupRepository.findAppGroup(with: previous.id) != nil else { return }

        openAppGroup(previous)
    }
}
