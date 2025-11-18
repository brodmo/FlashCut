import Foundation

enum AppConstants {
    static let mostRecentOption = MacApp(
        name: "(Most Recent)",
        bundleIdentifier: "flashcut.most-recent",
        iconPath: nil
    )

    static var version: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "Unknown"
        }

        #if DEBUG
        return version + " (debug)"
        #else
        return version
        #endif
    }
}
