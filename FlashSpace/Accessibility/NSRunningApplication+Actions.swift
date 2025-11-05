//
//  NSRunningApplication+Actions.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit

extension NSRunningApplication {
    func raise() {
        guard let mainWindow else {
            unhide()
            return
        }

        AXUIElementPerformAction(mainWindow, NSAccessibility.Action.raise as CFString)
    }

    /// Position is in window coordinates where (0,0) is top-left corner
    /// and it is relative to the main screen.
    func setPosition(_ position: CGPoint) {
        mainWindow?.setPosition(position)
    }

    func runWithoutAnimations(action: () -> ()) {
        let appElement = AXUIElementCreateApplication(processIdentifier)
        let wasEnabled = appElement.enhancedUserInterface

        if wasEnabled { appElement.setAttribute(.enchancedUserInterface, value: false) }

        action()

        if wasEnabled { appElement.setAttribute(.enchancedUserInterface, value: true) }
    }
}
