//
//  FocusSettingsView.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct FocusSettingsView: View {
    @StateObject private var settings = AppDependencies.shared.focusManagerSettings

    var body: some View {
        Form {
            Section("App Cycling") {
                hotkey("Focus Next App", for: $settings.focusNextAppGroupApp)
                hotkey("Focus Previous App", for: $settings.focusPreviousAppGroupApp)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Focus Manager")
    }
}
