//
//  AppDelegate.swift
//
//  Created by Wojciech Kulik on 13/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start as accessory app (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        AppDependencies.shared.hotKeysManager.enableAll()

        // Setup window opening notification handler (persists for app lifetime)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenMainWindow),
            name: .openMainWindow,
            object: nil
        )
    }

    @objc private func handleOpenMainWindow() {
        // Show Dock icon when opening window
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }

        // Post notification to actually open the window (handled by SwiftUI App)
        NotificationCenter.default.post(name: .openMainWindowInternal, object: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
