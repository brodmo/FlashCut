import Foundation
import Sparkle

final class UpdatesManager {
    static let shared = UpdatesManager()

    var autoCheckForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private init() {
        updaterController.updater.updateCheckInterval = 30 * 60

        DispatchQueue.main.async {
            self.autoCheckForUpdates = AppDependencies.shared.settings.checkForUpdatesAutomatically
        }
    }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}
