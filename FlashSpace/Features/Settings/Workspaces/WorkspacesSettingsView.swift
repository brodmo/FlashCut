//
//  WorkspacesSettingsView.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct WorkspacesSettingsView: View {
    @StateObject var settings = AppDependencies.shared.workspaceSettings

    var body: some View {
        Form {
            Section("Behaviors") {
                Toggle("Center Cursor In Focused App", isOn: $settings.centerCursorOnAppActivation)
                    .help("Centers the cursor when activating an app group")
            }

            Section("Group Cycling") {
                hotkey("Recent Group", for: $settings.switchToRecentWorkspace)
                hotkey("Previous Group", for: $settings.switchToPreviousWorkspace)
                hotkey("Next Group", for: $settings.switchToNextWorkspace)
                Toggle("Loop Groups", isOn: $settings.loopWorkspaces)
                    .help("Loop back to the first group when cycling past the last")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("App Groups")
    }
}
