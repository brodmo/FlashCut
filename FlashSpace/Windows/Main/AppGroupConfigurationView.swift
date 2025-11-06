//
//  AppGroupConfigurationView.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI
import AppKit

struct AppGroupConfigurationView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        if viewModel.selectedAppGroup != nil {
            VStack(alignment: .leading, spacing: 0.0) {
                configuration

                if viewModel.appGroups.contains(where: { $0.apps.contains(where: \.bundleIdentifier.isEmpty) }) {
                    Text("Could not migrate some apps. Please re-add them to fix the problem.")
                        .foregroundColor(.errorRed)
                }
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
                Text("Primary App")

                Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary)
                    .help("The primary app is always focused and launched if not running when activating this group")

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
