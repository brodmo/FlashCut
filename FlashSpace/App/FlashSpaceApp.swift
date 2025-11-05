//
//  FlashSpaceApp.swift
//  FlashCut
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import AppKit
import Combine
import SwiftUI

@main
struct FlashCutApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @AppStorage("firstLaunch") private var firstLaunch = true

    @State private var cancellables = Set<AnyCancellable>()

    var body: some Scene {
        Window("⚡ FlashCut v\(AppConstants.version)", id: "main") {
            WindowVisibilityHandler(
                showDockIcon: showDockIcon,
                hideDockIcon: hideDockIconIfNoWindows,
                setupHandlers: setupWindowHandling
            ) {
                MainView()
            }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Settings", id: "settings") {
            WindowVisibilityHandler(
                showDockIcon: showDockIcon,
                hideDockIcon: hideDockIconIfNoWindows
            ) {
                SettingsView()
            }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    private func setupWindowHandling() {
        // Setup notification handlers
        NotificationCenter.default
            .publisher(for: .openMainWindow)
            .sink { _ in
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            .store(in: &cancellables)

        // Hide main window on launch (except first time)
        if !firstLaunch {
            dismissWindow(id: "main")
        }
        firstLaunch = false
    }

    private func showDockIcon() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func hideDockIconIfNoWindows() {
        // Use a small delay to let window close animation complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let hasVisibleWindows = NSApp.windows.contains { window in
                window.isVisible && (
                    window.identifier?.rawValue == "main" ||
                    window.identifier?.rawValue == "settings"
                )
            }

            if !hasVisibleWindows {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
