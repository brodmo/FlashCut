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

    private func findApp(in appGroup: AppGroup) {
        // Determine which app to launch: target app or most recently activated
        let appToLaunch = appGroup.targetApp ?? appGroup.apps
            .max(by: { app1, app2 in
                let time1 = recentlyActivatedApps[app1.bundleIdentifier] ?? .distantPast
                let time2 = recentlyActivatedApps[app2.bundleIdentifier] ?? .distantPast
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
                Logger.log("Successfully launched and activated: \(app.localizedName ?? "app")")
            }
        }
    }
}

// MARK: - AppGroup Actions
extension AppGroupManager {
    func activateAppGroup(_ appGroup: AppGroup) {
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

        // Launch an app in the group
        findApp(in: appGroup)
    }

    func activateAppGroup(next: Bool, loop: Bool) {
        let appGroups = appGroupRepository.appGroups

        guard let currentAppGroup = lastActivatedAppGroup ?? appGroups.first else {
            // No appGroup activated yet, activate first one
            if let first = appGroups.first {
                activateAppGroup(first)
            }
            return
        }

        let appGroupsToLoop = next ? appGroups : appGroups.reversed()

        let nextAppGroups = appGroupsToLoop
            .drop(while: { $0.id != currentAppGroup.id })
            .dropFirst()

        let selectedAppGroup = nextAppGroups.first ?? (loop ? appGroupsToLoop.first : nil)

        guard let selectedAppGroup, selectedAppGroup.id != currentAppGroup.id else { return }

        activateAppGroup(selectedAppGroup)
    }

    func activateRecentAppGroup() {
        // Alt+Tab-like behavior for app groups: switch to previous appGroup
        guard let previous = previousActivatedAppGroup else { return }
        // Verify the appGroup still exists in the repository
        guard appGroupRepository.findAppGroup(with: previous.id) != nil else { return }

        activateAppGroup(previous)
    }
}
