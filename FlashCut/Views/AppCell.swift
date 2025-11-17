import SwiftUI

struct AppCell: View {
    let appGroupId: AppGroupID
    let app: MacApp

    var body: some View {
        HStack {
            if let iconPath = app.iconPath, let image = NSImage(byReferencingFile: iconPath) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            Text(app.name)
                .foregroundColor(app.bundleIdentifier.isEmpty ? .errorRed : .primary)
        }
        .draggable(MacAppWithAppGroup(app: app, appGroupId: appGroupId))
    }
}
