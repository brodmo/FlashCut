import AppKit

typealias BundleId = String

struct MacApp: Codable, Hashable, Equatable {
    var name: String
    var bundleIdentifier: BundleId
    var iconPath: String?

    init(
        name: String,
        bundleIdentifier: BundleId,
        iconPath: String?
    ) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.iconPath = iconPath
    }

    init(app: NSRunningApplication) {
        self.name = app.localizedName ?? ""
        self.bundleIdentifier = app.bundleIdentifier ?? ""
        self.iconPath = app.iconPath
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        self.iconPath = try container.decodeIfPresent(String.self, forKey: .iconPath)
    }

    static func == (lhs: MacApp, rhs: MacApp) -> Bool {
        if lhs.bundleIdentifier.isEmpty || rhs.bundleIdentifier.isEmpty {
            return lhs.name == rhs.name
        } else {
            return lhs.bundleIdentifier == rhs.bundleIdentifier
        }
    }
}

extension MacApp {
    static func fromBundleIdentifier(_ bundleIdentifier: BundleId) -> MacApp? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
              let bundle = Bundle(url: appURL) else {
            return nil
        }

        let name = bundle.localizedAppName
        let iconPath = bundle.iconPath

        return MacApp(
            name: name,
            bundleIdentifier: bundleIdentifier,
            iconPath: iconPath
        )
    }
}
