import AppKit
import Combine
import SwiftUI

@main
struct FlashCutApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    @State private var cancellables = Set<AnyCancellable>()

    init() {
        // Set faster tooltip delay (500ms instead of default ~1000ms)
        UserDefaults.standard.set(500, forKey: "NSInitialToolTipDelay")
    }

    var body: some Scene {
        Window("⚡ FlashCut v\(AppConstants.version)", id: "main") {
            MainView()
                .onAppear {
                    setupNotificationHandlers()
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

    private func setupNotificationHandlers() {
        // Listen for hotkey trigger to open window
        NotificationCenter.default
            .publisher(for: .openMainWindow)
            .sink { [self] _ in
                showDockIcon()
                openWindow(id: "main")
            }
            .store(in: &cancellables)
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
