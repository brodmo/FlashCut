import Foundation
import Sparkle

final class UpdatesManager {
    static let shared = UpdatesManager()

    private static let updateCheckIntervalSeconds: TimeInterval = 30 * 60 // 30 minutes

    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private init() {
        updaterController.updater.updateCheckInterval = Self.updateCheckIntervalSeconds
    }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}
