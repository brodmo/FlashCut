import ShortcutRecorder

struct AppDependencies {
    static let shared = AppDependencies()

    let appGroupRepository: AppGroupRepository
    let appGroupManager: AppGroupManager
    let appGroupHotKeys: AppGroupHotKeys

    let hotKeysMonitor: HotKeysMonitorProtocol = GlobalShortcutMonitor.shared
    let hotKeysManager: HotKeysManager

    let appManager: AppManager

    let settingsRepository: SettingsRepository
    let settings = Settings()

    let autostartService = AutostartService()

    private init() {
        self.appGroupRepository = AppGroupRepository()
        self.settingsRepository = SettingsRepository(settings: settings)

        // Wire up app group repository with settings repository
        appGroupRepository.configure(settingsRepository: settingsRepository)
        settingsRepository.setAppGroupRepository(appGroupRepository)

        self.appGroupManager = AppGroupManager(
            appGroupRepository: appGroupRepository,
            settingsRepository: settingsRepository
        )
        self.appGroupHotKeys = AppGroupHotKeys(
            appGroupManager: appGroupManager,
            appGroupRepository: appGroupRepository,
            settingsRepository: settingsRepository
        )
        self.appManager = AppManager(
            appGroupRepository: appGroupRepository,
            appGroupManager: appGroupManager,
            settings: settings
        )
        self.hotKeysManager = HotKeysManager(
            hotKeysMonitor: GlobalShortcutMonitor.shared,
            appGroupHotKeys: appGroupHotKeys,
            appManager: appManager,
            settingsRepository: settingsRepository
        )
    }
}
