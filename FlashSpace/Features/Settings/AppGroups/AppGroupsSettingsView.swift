//
//  AppGroupsSettingsView.swift
//
//  Created by Wojciech Kulik on 24/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct AppGroupsSettingsView: View {
    @StateObject var settings = AppDependencies.shared.appGroupSettings
    @StateObject var appManagerSettings = AppDependencies.shared.appManagerSettings

    var body: some View {
        Form {
            Section("Group Cycling") {
                hotkey("Recent Group", for: $settings.switchToRecentAppGroup)
                hotkey("Previous Group", for: $settings.switchToPreviousAppGroup)
                hotkey("Next Group", for: $settings.switchToNextAppGroup)
                Toggle("Loop Groups", isOn: $settings.loopAppGroups)
                    .help("Loop back to the first group when cycling past the last")
            }

            Section("App Switching Within Group") {
                hotkey("Switch to Next App in Group", for: $appManagerSettings.switchToNextAppInGroup)
                hotkey("Switch to Previous App in Group", for: $appManagerSettings.switchToPreviousAppInGroup)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("App Groups")
    }
}
