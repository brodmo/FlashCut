//
//  SettingsView.swift
//
//  Created by Wojciech Kulik on 23/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedTab = "General"

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn), sidebar: {
            sideMenu
                .frame(width: 200)
                .navigationSplitViewColumnWidth(200.0)
        }, detail: {
            details
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationSplitViewColumnWidth(min: 440, ideal: 440)
        })
        .frame(width: 780, height: 490)
    }

    private var sideMenu: some View {
        VStack {
            List(selection: $selectedTab) {
                Label("General", systemImage: "gearshape")
                    .tag("General")
                Label("App Groups", systemImage: "square.stack.3d.up")
                    .tag("Workspaces")
                Label("Focus Manager", systemImage: "macwindow.on.rectangle")
                    .tag("Focus")
                Label("Configuration File", systemImage: "doc.text")
                    .tag("Configuration")
                Label("Acknowledgements", systemImage: "info.circle")
                    .tag("Acknowledgements")
                Label("About", systemImage: "person")
                    .tag("About")
            }
            .toolbar(removing: .sidebarToggle)
            .listStyle(.sidebar)

            Spacer()

            Text("FlashCut v\(AppConstants.version)")
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
    }

    @ViewBuilder
    private var details: some View {
        switch selectedTab {
        case "General":
            GeneralSettingsView()
        case "Focus":
            FocusSettingsView()
        case "Workspaces":
            WorkspacesSettingsView()
        case "Configuration":
            ConfigurationFileSettingsView()
        case "Acknowledgements":
            AcknowledgementsSettingsView()
        case "About":
            AboutSettingsView()
        default:
            EmptyView()
        }
    }
}
