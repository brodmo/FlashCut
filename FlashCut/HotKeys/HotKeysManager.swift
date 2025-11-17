import AppKit
import Combine
import ShortcutRecorder

final class HotKeysManager {
    private(set) var allHotKeys: [(scope: String, hotKey: AppHotKey)] = []

    private var cancellables = Set<AnyCancellable>()

    private let hotKeysMonitor: HotKeysMonitorProtocol
    private let appGroupHotKeys: AppGroupHotKeys
    private let appManager: AppManager
    private let settingsRepository: ConfigRepository

    init(
        hotKeysMonitor: HotKeysMonitorProtocol,
        appGroupHotKeys: AppGroupHotKeys,
        appManager: AppManager,
        settingsRepository: ConfigRepository
    ) {
        self.hotKeysMonitor = hotKeysMonitor
        self.appGroupHotKeys = appGroupHotKeys
        self.appManager = appManager
        self.settingsRepository = settingsRepository

        observe()
    }

    func refresh() {
        disableAll()
        enableAll()
    }

    func enableAll() {
        allHotKeys.removeAll()
        let addShortcut = { (title: String, shortcut: Shortcut) in
            self.allHotKeys.append((title, .init(
                keyCode: shortcut.keyCode.rawValue,
                modifiers: shortcut.modifierFlags.rawValue
            )))
        }

        // App Groups
        for (shortcut, action) in appGroupHotKeys.getHotKeys().toShortcutPairs() {
            let action = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }

            hotKeysMonitor.addAction(action, forKeyEvent: .down)
            addShortcut("AppGroup", shortcut)
        }

        // App Manager
        for (shortcut, action) in appManager.getHotKeys().toShortcutPairs() {
            let action = ShortcutAction(shortcut: shortcut) { _ in
                action()
                return true
            }
            hotKeysMonitor.addAction(action, forKeyEvent: .down)
            addShortcut("App Manager", shortcut)
        }
    }

    func disableAll() {
        hotKeysMonitor.removeAllActions()
    }

    private func observe() {
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
