//
//  WorkspaceSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class AppGroupSettings: ObservableObject {
    @Published var centerCursorOnAppActivation = false

    @Published var loopAppGroups = true
    @Published var switchToRecentAppGroup: AppHotKey?
    @Published var switchToPreviousAppGroup: AppHotKey?
    @Published var switchToNextAppGroup: AppHotKey?

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $centerCursorOnAppActivation.settingsPublisher(),

            $loopAppGroups.settingsPublisher(),
            $switchToRecentAppGroup.settingsPublisher(),
            $switchToPreviousAppGroup.settingsPublisher(),
            $switchToNextAppGroup.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension AppGroupSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        centerCursorOnAppActivation = appSettings.centerCursorOnAppActivation ?? false

        loopAppGroups = appSettings.loopAppGroups ?? true
        switchToRecentAppGroup = appSettings.switchToRecentAppGroup
        switchToPreviousAppGroup = appSettings.switchToPreviousAppGroup
        switchToNextAppGroup = appSettings.switchToNextAppGroup
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.centerCursorOnAppActivation = centerCursorOnAppActivation

        appSettings.loopAppGroups = loopAppGroups
        appSettings.switchToRecentAppGroup = switchToRecentAppGroup
        appSettings.switchToPreviousAppGroup = switchToPreviousAppGroup
        appSettings.switchToNextAppGroup = switchToNextAppGroup
    }
}
