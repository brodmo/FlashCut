import AppKit
import SwiftUI

struct AppGroupConfigurationView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            configuration

            if viewModel.appGroups.contains(where: { $0.apps.contains(where: \.bundleIdentifier.isEmpty) }) {
                Text("Could not migrate some apps. Please re-add them to fix the problem.")
                    .foregroundColor(.errorRed)
            }
        }
    }

    private var configuration: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Shortcut
            HotKeyControl(shortcut: $viewModel.appGroupShortcut)

            Spacer()
                .frame(height: 16)

            // Primary App with tooltip
            HStack(spacing: 4) {
                Text("Main")

                Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary)
                    .help("The Main App is always opened, even if it is not yet running")

                Spacer()

                Picker("", selection: $viewModel.appGroupTargetApp) {
                    ForEach(viewModel.targetAppOptions, id: \.self) { app in
                        Text(app.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .tag(app)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 100)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
