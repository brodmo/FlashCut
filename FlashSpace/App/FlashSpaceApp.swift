//
//  FlashSpaceApp.swift
//  FlashCut
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import SwiftUI

@main
struct FlashCutApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("⚡ FlashCut v\(AppConstants.version)", id: "main") {
            MainView()
        }
        .windowResizability(.contentSize)

        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)

        FlashCutMenuBar()
    }
}
