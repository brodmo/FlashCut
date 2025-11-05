//
//  WorkspacesSettingsView.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct AppGroupsSettingsView: View {
    @StateObject var settings = AppDependencies.shared.appGroupSettings

    var body: some View {
        Form {
            Section("Behaviors") {
                Toggle("Center Cursor In Focused App", isOn: $settings.centerCursorOnAppActivation)
                    .help("Centers the cursor when activating an app group")
            }

            Section("Group Cycling") {
                hotkey("Recent Group", for: $settings.switchToRecentAppGroup)
                hotkey("Previous Group", for: $settings.switchToPreviousAppGroup)
                hotkey("Next Group", for: $settings.switchToNextAppGroup)
                Toggle("Loop Groups", isOn: $settings.loopAppGroups)
                    .help("Loop back to the first group when cycling past the last")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("App Groups")
    }
}
