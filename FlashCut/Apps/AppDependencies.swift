import ShortcutRecorder

struct AppDependencies {
    static let shared = AppDependencies()

    let appGroupRepository: AppGroupRepository
    let appGroupManager: AppGroupManager
    let appGroupHotKeys: AppGroupHotKeys

    let hotKeysMonitor: HotKeysMonitorProtocol = GlobalShortcutMonitor.shared
    let hotKeysManager: HotKeysManager

    let appManager: AppManager

    let configRepository: ConfigRepository

    let autostartService = AutostartService()

    private init() {
        self.appGroupRepository = AppGroupRepository()
        self.configRepository = ConfigRepository()

        // Wire up app group repository with config repository
        appGroupRepository.configure(settingsRepository: configRepository)
        configRepository.setAppGroupRepository(appGroupRepository)

        self.appGroupManager = AppGroupManager(
            appGroupRepository: appGroupRepository,
            settingsRepository: configRepository
        )
        self.appGroupHotKeys = AppGroupHotKeys(
            appGroupManager: appGroupManager,
            appGroupRepository: appGroupRepository,
            settingsRepository: configRepository
        )
        self.appManager = AppManager(
            appGroupRepository: appGroupRepository,
            appGroupManager: appGroupManager,
            settings: configRepository.settings
        )
        self.hotKeysManager = HotKeysManager(
            hotKeysMonitor: GlobalShortcutMonitor.shared,
            appGroupHotKeys: appGroupHotKeys,
            appManager: appManager,
            settingsRepository: configRepository
        )
    }
}
