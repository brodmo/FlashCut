//
//  AppSettings.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

struct AppSettings: Codable {
    // General
    var checkForUpdatesAutomatically: Bool?
    var showFlashSpace: AppHotKey?
    var showFloatingNotifications: Bool?

    // Focus Manager
    var enableFocusManagement: Bool?
    var centerCursorOnFocusChange: Bool?
    var focusNextWorkspaceApp: AppHotKey?
    var focusPreviousWorkspaceApp: AppHotKey?
    var focusNextWorkspaceWindow: AppHotKey?
    var focusPreviousWorkspaceWindow: AppHotKey?

    // Workspaces
    var centerCursorOnAppActivation: Bool?
    var loopWorkspaces: Bool?
    var assignFocusedApp: AppHotKey?
    var unassignFocusedApp: AppHotKey?
    var toggleFocusedAppAssignment: AppHotKey?
    var assignVisibleApps: AppHotKey?
    var switchToRecentWorkspace: AppHotKey?
    var switchToPreviousWorkspace: AppHotKey?
    var switchToNextWorkspace: AppHotKey?
}
