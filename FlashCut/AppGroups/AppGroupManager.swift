import AppKit
import Combine

final class AppGroupManager: ObservableObject {
    // Minimal state for cycling and recent appGroup switching
    private var lastAppGroup: AppGroup?
    private var currentAppGroup: AppGroup?

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

    private func openApp(in appGroup: AppGroup) {
        if let targetApp = appGroup.targetApp {
            // Target app: launch even if not running
            launchApp(targetApp)
        } else {
            // No target app: activate most recent running app
            if let mostRecentRunning = findMostRecentRunningApp(from: appGroup.apps) {
                activateRunningApp(mostRecentRunning)
            }
        }
    }

    private func findMostRecentRunningApp(from apps: [MacApp]) -> MacApp? {
        let runningApps = NSWorkspace.shared.runningApplications
        let runningGroupApps = apps.filter { app in
            runningApps.contains { $0.bundleIdentifier == app.bundleIdentifier }
        }
        return runningGroupApps.max(by: { app1, app2 in
            let time1 = recentApps[app1.bundleIdentifier] ?? .distantPast
            let time2 = recentApps[app2.bundleIdentifier] ?? .distantPast
            return time1 < time2
        })
    }

    private func activateRunningApp(_ app: MacApp) {
        guard let runningApp = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == app.bundleIdentifier
        }) else {
            Logger.log("App not running, cannot activate: \(app.name)")
            return
        }
        Logger.log("Activating app: \(app.name)")
        if runningApp.isHidden {
            runningApp.unhide()
        }
        runningApp.activate() // TODO: Maybe consolidate with the cycle apps activation
    }

    private func launchApp(_ app: MacApp) {
        guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) else {
            Logger.log("Failed to find app URL for: \(app.name)")
            return
        }

        Logger.log("Launching primary app: \(app.name)")

        // Note: OpenConfiguration activates by default (brings app to foreground)
        let configuration = NSWorkspace.OpenConfiguration()
        // Prevent Firefox troubleshoot mode dialog when modifier keys are held
        // (common when launching via keyboard shortcuts)
        configuration.environment = ["MOZ_DISABLE_SAFE_MODE_KEY": "1"]
        NSWorkspace.shared.openApplication(at: appUrl, configuration: configuration) { app, error in
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
        if let last = currentAppGroup, last.id != appGroup.id {
            lastAppGroup = last
        }
        currentAppGroup = appGroup
        openApp(in: appGroup)
    }

    /// Switches to the previously active app group (Alt+Tab-like behavior).
    ///
    /// This method activates the app group that was active before the current one,
    /// enabling quick switching between two groups. Does nothing if there is no
    /// previous group or if the previous group no longer exists.
    func openLastAppGroup() {
        guard let previous = lastAppGroup else { return }
        // Verify the appGroup still exists in the repository
        guard appGroupRepository.findAppGroup(with: previous.id) != nil else { return }
        openAppGroup(previous)
    }
}
