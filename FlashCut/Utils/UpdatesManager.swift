import Foundation
import Sparkle

final class UpdatesManager {
    static let shared = UpdatesManager()

    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private init() {
        updaterController.updater.updateCheckInterval = 30 * 60
    }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}
