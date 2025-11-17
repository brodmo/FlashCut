import AppKit
import Foundation
import UniformTypeIdentifiers

final class FileChooser {
    func runModalOpenPanel(allowedFileTypes: [UTType]?, directoryURL: URL?) -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = allowedFileTypes ?? []
        openPanel.directoryURL = directoryURL
        return openPanel.runModal() == .OK ? openPanel.url : nil
    }
}
