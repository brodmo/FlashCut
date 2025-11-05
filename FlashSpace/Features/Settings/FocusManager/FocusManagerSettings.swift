//
//  FocusManagerSettings.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Combine
import Foundation

final class FocusManagerSettings: ObservableObject {
    @Published var focusNextAppGroupApp: AppHotKey?
    @Published var focusPreviousAppGroupApp: AppHotKey?
    @Published var focusNextAppGroupWindow: AppHotKey?
    @Published var focusPreviousAppGroupWindow: AppHotKey?

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $focusNextAppGroupApp.settingsPublisher(),
            $focusPreviousAppGroupApp.settingsPublisher(),
            $focusNextAppGroupWindow.settingsPublisher(),
            $focusPreviousAppGroupWindow.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension FocusManagerSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        focusNextAppGroupApp = appSettings.focusNextAppGroupApp
        focusPreviousAppGroupApp = appSettings.focusPreviousAppGroupApp
        focusNextAppGroupWindow = appSettings.focusNextAppGroupWindow
        focusPreviousAppGroupWindow = appSettings.focusPreviousAppGroupWindow
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.focusNextAppGroupApp = focusNextAppGroupApp
        appSettings.focusPreviousAppGroupApp = focusPreviousAppGroupApp
        appSettings.focusNextAppGroupWindow = focusNextAppGroupWindow
        appSettings.focusPreviousAppGroupWindow = focusPreviousAppGroupWindow
    }
}
