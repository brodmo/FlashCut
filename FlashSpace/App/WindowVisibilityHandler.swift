//
//  WindowVisibilityHandler.swift
//  FlashCut
//
//  Created by Claude on 05/11/2025.
//  Copyright © 2025 FlashCut. All rights reserved.
//

import SwiftUI

struct WindowVisibilityHandler<Content: View>: View {
    let showDockIcon: () -> Void
    let hideDockIcon: () -> Void
    let setupHandlers: (() -> Void)?
    let content: Content

    @State private var hasSetup = false

    init(
        showDockIcon: @escaping () -> Void,
        hideDockIcon: @escaping () -> Void,
        setupHandlers: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.showDockIcon = showDockIcon
        self.hideDockIcon = hideDockIcon
        self.setupHandlers = setupHandlers
        self.content = content()
    }

    var body: some View {
        content
            .onAppear {
                if !hasSetup, let setup = setupHandlers {
                    setup()
                    hasSetup = true
                }
                showDockIcon()
            }
            .onDisappear {
                hideDockIcon()
            }
    }
}
