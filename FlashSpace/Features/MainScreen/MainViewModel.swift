//
//  MainViewModel.swift
//
//  Created by Wojciech Kulik on 19/01/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import AppKit
import Combine
import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var appGroups: [AppGroup] = [] {
        didSet {
            guard appGroups.count == oldValue.count,
                  appGroups.map(\.id) != oldValue.map(\.id) else { return }

            appGroupRepository.reorderAppGroups(newOrder: appGroups.map(\.id))
        }
    }

    @Published var appGroupApps: [MacApp]?

    @Published var appGroupName = ""
    @Published var appGroupShortcut: AppHotKey? {
        didSet { saveAppGroup() }
    }

    @Published var appGroupTargetApp: MacApp? = AppConstants.lastFocusedOption {
        didSet { saveAppGroup() }
    }

    @Published var isOpenAppsOnActivationEnabled = false {
        didSet { saveAppGroup() }
    }

    @Published var isInputDialogPresented = false
    @Published var userInput = ""

    var targetAppOptions: [MacApp] {
        [AppConstants.lastFocusedOption] + (appGroupApps ?? [])
    }

    var selectedApps: Set<MacApp> = [] {
        didSet {
            // To avoid warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
                objectWillChange.send()
            }
        }
    }

    var selectedAppGroups: Set<AppGroup> = [] {
        didSet {
            selectedAppGroup = selectedAppGroups.count == 1
                ? selectedAppGroups.first
                : nil

            // To avoid warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
                if selectedAppGroups.count == 1,
                   selectedAppGroups.first?.id != oldValue.first?.id {
                    selectedApps = []
                } else if selectedAppGroups.count != 1 {
                    selectedApps = []
                }
                objectWillChange.send()
            }
        }
    }

    private(set) var selectedAppGroup: AppGroup? {
        didSet {
            guard selectedAppGroup != oldValue else { return }

            // To avoid warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.updateSelectedAppGroup()
            }
        }
    }

    private var cancellables: Set<AnyCancellable> = []
    private var loadingAppGroup = false

    private let appGroupManager = AppDependencies.shared.appGroupManager
    private let appGroupRepository = AppDependencies.shared.appGroupRepository
    private let appGroupSettings = AppDependencies.shared.appGroupSettings

    init() {
        self.appGroups = appGroupRepository.appGroups
        observe()
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: .appsListChanged)
            .sink { [weak self] _ in self?.reloadAppGroups() }
            .store(in: &cancellables)
    }

    private func updateSelectedAppGroup() {
        loadingAppGroup = true
        defer { loadingAppGroup = false }

        appGroupName = selectedAppGroup?.name ?? ""
        appGroupShortcut = selectedAppGroup?.activateShortcut
        appGroupApps = selectedAppGroup?.apps
        appGroupTargetApp = selectedAppGroup?.targetApp ?? AppConstants.lastFocusedOption
        isOpenAppsOnActivationEnabled = selectedAppGroup?.openAppsOnActivation ?? false
        selectedAppGroup.flatMap { selectedAppGroups = [$0] }
    }

    private func reloadAppGroups() {
        appGroups = appGroupRepository.appGroups
        if let selectedAppGroup, let appGroup = appGroupRepository.findAppGroup(with: selectedAppGroup.id) {
            selectedAppGroups = [appGroup]
        } else {
            selectedAppGroups = []
        }
        selectedApps = []
    }
}

extension MainViewModel {
    func saveAppGroup() {
        guard let selectedAppGroup, !loadingAppGroup else { return }

        if appGroupName.trimmingCharacters(in: .whitespaces).isEmpty {
            appGroupName = "(empty)"
        }

        let updatedAppGroup = AppGroup(
            id: selectedAppGroup.id,
            name: appGroupName,
            activateShortcut: appGroupShortcut,
            apps: selectedAppGroup.apps,
            targetApp: appGroupTargetApp == AppConstants.lastFocusedOption ? nil : appGroupTargetApp,
            openAppsOnActivation: isOpenAppsOnActivationEnabled
        )

        appGroupRepository.updateAppGroup(updatedAppGroup)
        appGroups = appGroupRepository.appGroups
        self.selectedAppGroup = appGroupRepository.findAppGroup(with: selectedAppGroup.id)
    }

    func addAppGroup() {
        userInput = ""
        isInputDialogPresented = true

        $isInputDialogPresented
            .first { !$0 }
            .sink { [weak self] _ in
                guard let self, !self.userInput.isEmpty else { return }

                self.appGroupRepository.addAppGroup(name: self.userInput)
                self.appGroups = self.appGroupRepository.appGroups
                self.selectedAppGroup = self.appGroups.last
            }
            .store(in: &cancellables)
    }

    func deleteSelectedAppGroups() {
        guard !selectedAppGroups.isEmpty else { return }

        appGroupRepository.deleteAppGroups(ids: selectedAppGroups.map(\.id).asSet)
        appGroups = appGroupRepository.appGroups
        selectedAppGroups = []
    }

    func addApp() {
        guard let selectedAppGroup else { return }

        let fileChooser = FileChooser()
        let appUrl = fileChooser.runModalOpenPanel(
            allowedFileTypes: [.application],
            directoryURL: URL(filePath: "/Applications")
        )

        guard let appUrl else { return }

        let appName = appUrl.appName
        let appBundleId = appUrl.bundleIdentifier ?? ""
        let runningApp = NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == appBundleId }
        let isAgent = appUrl.bundle?.isAgent == true && (runningApp == nil || runningApp?.activationPolicy != .regular)

        guard !isAgent else {
            Alert.showOkAlert(
                title: appName,
                message: "This application is an agent (runs in background) and cannot be managed by FlashCut."
            )
            return
        }

        guard !selectedAppGroup.apps.containsApp(with: appBundleId) else { return }

        appGroupRepository.addApp(
            to: selectedAppGroup.id,
            app: .init(
                name: appName,
                bundleIdentifier: appBundleId,
                iconPath: appUrl.iconPath
            )
        )

        appGroups = appGroupRepository.appGroups
        self.selectedAppGroup = appGroupRepository.findAppGroup(with: selectedAppGroup.id)

        appGroupManager.activateAppGroupIfActive(selectedAppGroup.id)
    }

    func deleteSelectedApps() {
        guard let selectedAppGroup, !selectedApps.isEmpty else { return }

        let selectedApps = Array(selectedApps)

        for app in selectedApps {
            appGroupRepository.deleteApp(
                from: selectedAppGroup.id,
                app: app,
                notify: app == selectedApps.last
            )
        }

        appGroups = appGroupRepository.appGroups
        self.selectedAppGroup = appGroupRepository.findAppGroup(with: selectedAppGroup.id)
        appGroupApps = self.selectedAppGroup?.apps
        self.selectedApps = []

        appGroupManager.activateAppGroupIfActive(selectedAppGroup.id)
    }
}
