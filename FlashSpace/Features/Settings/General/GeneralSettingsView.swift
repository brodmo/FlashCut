//
//  GeneralSettingsView.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    @StateObject var settings = AppDependencies.shared.generalSettings
    @State var isAutostartEnabled = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at startup", isOn: $isAutostartEnabled)
                Toggle("Check for updates automatically", isOn: $settings.checkForUpdatesAutomatically)
            }

            Section("Shortcuts") {
                hotkey("Toggle FlashCut Window", for: $settings.showFlashCut)
            }

            Section("Configuration File") {
                HStack {
                    Text("Format: TOML")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Location:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.open(ConfigSerializer.configDirectory)
                    }
                }

                Text(
                    "Manual edits require a restart. Formatting and comments will be overwritten when changed in the app."
                )
                .foregroundStyle(.secondary)
                .font(.callout)
            }
        }
        .onAppear {
            isAutostartEnabled = AppDependencies.shared.autostartService.isLaunchAtLoginEnabled
        }
        .onChange(of: isAutostartEnabled) { _, enabled in
            if enabled {
                AppDependencies.shared.autostartService.enableLaunchAtLogin()
            } else {
                AppDependencies.shared.autostartService.disableLaunchAtLogin()
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}
