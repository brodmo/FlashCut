import AppKit
import Combine
import SwiftUI

@main
struct FlashCutApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    private static let tooltipDelayMilliseconds = 500 // Faster than default ~1000ms
    private static let windowCloseAnimationDelay: TimeInterval = 0.1

    init() {
        UserDefaults.standard.set(Self.tooltipDelayMilliseconds, forKey: "NSInitialToolTipDelay")
    }

    var body: some Scene {
        Window("⚡ FlashCut v\(AppConstants.version)", id: "main") {
            MainView()
                .onAppear {
                    showDockIcon()
                }
                .onDisappear {
                    hideDockIconIfNoWindows()
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Settings", id: "settings") {
            SettingsView()
                .onAppear {
                    showDockIcon()
                }
                .onDisappear {
                    hideDockIconIfNoWindows()
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    private func showDockIcon() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func hideDockIconIfNoWindows() {
        // Use a small delay to let window close animation complete
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.windowCloseAnimationDelay) {
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
