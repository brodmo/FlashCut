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

            Section("App Assignment") {
                hotkey("Assign Visible Apps", for: $settings.assignVisibleApps)
                hotkey("Assign Focused App", for: $settings.assignFocusedApp)
                hotkey("Unassign Focused App", for: $settings.unassignFocusedApp)
                hotkey("Toggle Focused App Assignment", for: $settings.toggleFocusedAppAssignment)
            }

            Section("Group Cycling") {
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
