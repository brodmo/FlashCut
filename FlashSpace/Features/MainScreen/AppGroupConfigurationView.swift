//
//  AppGroupConfigurationView.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct AppGroupConfigurationView: View {
    @Environment(\.openWindow) var openWindow

    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            configuration

            if viewModel.appGroups.contains(where: { $0.apps.contains(where: \.bundleIdentifier.isEmpty) }) {
                Text("Could not migrate some apps. Please re-add them to fix the problem.")
                    .foregroundColor(.errorRed)
            }

            Spacer()
            settingsButton
        }
    }

    private var configuration: some View {
        VStack(alignment: .leading, spacing: 1.0) {
            Text("App Group Configuration:")
                .padding(.bottom, 16.0)
                .fixedSize()

            Text("Name:").padding(.bottom, 2.0)
            TextField("Name", text: $viewModel.appGroupName)
                .onSubmit(viewModel.saveAppGroup)
                .padding(.bottom)

            Picker("Primary App:", selection: $viewModel.appGroupTargetApp) {
                ForEach(viewModel.targetAppOptions, id: \.self) {
                    Text($0.name.padEnd(toLength: 20)).tag($0)
                }
            }.padding(.bottom)

            Text("Activate Shortcut:")
            HotKeyControl(shortcut: $viewModel.appGroupShortcut).padding(.bottom)

            Toggle("Open apps on activation", isOn: $viewModel.isOpenAppsOnActivationEnabled).padding(.bottom)
        }
        .disabled(viewModel.selectedAppGroup == nil)
    }

    private var settingsButton: some View {
        HStack {
            Button(action: {
                openWindow(id: "settings")
            }, label: {
                Image(systemName: "gearshape")
                    .foregroundColor(.primary)
            }).keyboardShortcut(",")
        }.frame(maxWidth: .infinity, alignment: .trailing)
    }
}
