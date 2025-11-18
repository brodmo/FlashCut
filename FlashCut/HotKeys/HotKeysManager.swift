import AppKit
import Combine
import ShortcutRecorder

final class HotKeysManager {
    private(set) var shortcuts: [Shortcut] = []

    private var cancellables = Set<AnyCancellable>()

    private let hotKeysMonitor: HotKeysMonitorProtocol
    private let appManager: AppManager
    private let appGroupManager: AppGroupManager
    private let appGroupRepository: AppGroupRepository
    private let settingsRepository: ConfigRepository

    init(
        hotKeysMonitor: HotKeysMonitorProtocol,
        appManager: AppManager,
        appGroupManager: AppGroupManager,
        appGroupRepository: AppGroupRepository,
        settingsRepository: ConfigRepository
    ) {
        self.hotKeysMonitor = hotKeysMonitor
        self.appManager = appManager
        self.appGroupManager = appGroupManager
        self.appGroupRepository = appGroupRepository
        self.settingsRepository = settingsRepository

        observe()
    }

    /// Refreshes all hotkey registrations by disabling and re-enabling them.
    ///
    /// Call this method after configuration changes to update the active hotkeys
    /// to match the current settings and app groups.
    func refresh() {
        disableAll()
        enableAll()
    }

    /// Registers all hotkeys from app groups and settings with the system.
    ///
    /// This method registers global hotkeys for:
    /// - Each app group's activation shortcut
    /// - The "last app group" switch shortcut (if configured)
    /// - The "cycle apps in group" shortcut (if configured)
    ///
    /// Clears any previously registered shortcuts before registering new ones.
    func enableAll() {
        shortcuts.removeAll()
        var hotkeys: [(AppHotKey, () -> ())] = []

        hotkeys += appGroupRepository.appGroups.compactMap { appGroup in
            guard let shortcut = appGroup.shortcut else { return nil }
            let action = { [weak self] in
                guard let self, let updatedAppGroup = appGroupRepository.findAppGroup(with: appGroup.id) else { return }
                appGroupManager.openAppGroup(updatedAppGroup)
            }
            return (shortcut, action)
        }

        if let shortcut = settingsRepository.config.settings.lastAppGroup {
            hotkeys.append((shortcut, { [weak self] in self?.appGroupManager.openLastAppGroup() }))
        }

        if let shortcut = settingsRepository.config.settings.cycleAppsInGroup {
            hotkeys.append((shortcut, { [weak self] in self?.appManager.cycleAppsInGroup() }))
        }

        for (hotKey, action) in hotkeys {
            guard let shortcut = hotKey.toShortcut() else { continue }
            let shortcutAction = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }
            hotKeysMonitor.addAction(shortcutAction, forKeyEvent: .down)
            shortcuts.append(shortcut)
        }
    }

    /// Unregisters all hotkeys from the system.
    ///
    /// Call this method when the app is shutting down or before
    /// re-registering hotkeys with different configurations.
    func disableAll() {
        hotKeysMonitor.removeAllActions()
    }

    private func observe() {
        // Update hotkeys when keyboard layout is changed
        DistributedNotificationCenter.default()
            .publisher(for: .init(rawValue: kTISNotifySelectedKeyboardInputSourceChanged as String))
            .sink { [weak self] _ in
                KeyCodesMap.refresh()
                self?.disableAll()
                self?.enableAll()
            }
            .store(in: &cancellables)
    }
}
