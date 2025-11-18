import ShortcutRecorder

struct AppDependencies {
    static let shared = AppDependencies()

    let appGroupRepository: AppGroupRepository
    let appGroupManager: AppGroupManager

    let hotKeysMonitor: HotKeysMonitorProtocol = GlobalShortcutMonitor.shared
    let hotKeysManager: HotKeysManager

    let appManager: AppManager

    let configRepository: ConfigRepository

    let autostartService = AutostartService()

    private init() {
        self.configRepository = ConfigRepository()
        self.appGroupRepository = AppGroupRepository(configRepository: configRepository)

        self.appGroupManager = AppGroupManager(appGroupRepository: appGroupRepository)
        self.appManager = AppManager(
            appGroupRepository: appGroupRepository,
            appGroupManager: appGroupManager,
            settings: configRepository.config.settings
        )
        self.hotKeysManager = HotKeysManager(
            hotKeysMonitor: GlobalShortcutMonitor.shared,
            appManager: appManager,
            appGroupManager: appGroupManager,
            appGroupRepository: appGroupRepository,
            settingsRepository: configRepository
        )

        // Set up callback to refresh hotkeys when config changes
        configRepository.onConfigChanged = { [weak hotKeysManager] in
            hotKeysManager?.refresh()
        }
    }
}
