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

    // Focus Manager
    var focusNextAppGroupApp: AppHotKey?
    var focusPreviousAppGroupApp: AppHotKey?
    var focusNextAppGroupWindow: AppHotKey?
    var focusPreviousAppGroupWindow: AppHotKey?

    // App Groups
    var centerCursorOnAppActivation: Bool?
    var loopAppGroups: Bool?
    var switchToRecentAppGroup: AppHotKey?
    var switchToPreviousAppGroup: AppHotKey?
    var switchToNextAppGroup: AppHotKey?
}
