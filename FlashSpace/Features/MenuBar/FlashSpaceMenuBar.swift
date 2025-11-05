//
//  FlashSpaceMenuBar.swift
//
//  Created by Wojciech Kulik on 13/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI

struct FlashCutMenuBar: Scene {
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            Text("FlashCut v\(AppConstants.version)")

            Button("Open") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("Settings") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }.keyboardShortcut(",")

            Divider()

            Button("Check for Updates") {
                UpdatesManager.shared.checkForUpdates()
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }.keyboardShortcut("q")
        } label: {
            Text("FlashCut")
        }
    }
}
