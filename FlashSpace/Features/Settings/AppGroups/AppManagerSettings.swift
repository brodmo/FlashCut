//
//  AppManagerSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class AppManagerSettings: ObservableObject {
    @Published var switchToNextAppInGroup: AppHotKey?
    @Published var switchToPreviousAppInGroup: AppHotKey?

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $switchToNextAppInGroup.settingsPublisher(),
            $switchToPreviousAppInGroup.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension AppManagerSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        switchToNextAppInGroup = appSettings.switchToNextAppInGroup
        switchToPreviousAppInGroup = appSettings.switchToPreviousAppInGroup
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.switchToNextAppInGroup = switchToNextAppInGroup
        appSettings.switchToPreviousAppInGroup = switchToPreviousAppInGroup
    }
}
