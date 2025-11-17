import AppKit

extension NSRunningApplication {
    var iconPath: String? { bundleURL?.iconPath }
}

extension [NSRunningApplication] {
    func find(_ app: MacApp?) -> NSRunningApplication? {
        guard let app else { return nil }

        return first { $0.bundleIdentifier == app.bundleIdentifier }
    }
}
