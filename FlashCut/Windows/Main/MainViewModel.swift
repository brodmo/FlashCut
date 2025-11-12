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

    @Published var newlyCreatedAppGroupId: UUID?
    @Published var editingAppGroupId: UUID?

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

    @Published var selectedAppGroupIds: Set<UUID> = [] {
        didSet {
            selectedAppGroup = selectedAppGroupIds.count == 1
                ? appGroups.first(where: { selectedAppGroupIds.contains($0.id) })
                : nil

            // To avoid warnings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
                if selectedAppGroupIds.count == 1,
                   selectedAppGroupIds.first != oldValue.first {
                    selectedApps = []
                } else if selectedAppGroupIds.count != 1 {
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
        selectedAppGroup.flatMap { selectedAppGroupIds = [$0.id] }
    }

    private func reloadAppGroups() {
        appGroups = appGroupRepository.appGroups
        if let selectedAppGroup, let appGroup = appGroupRepository.findAppGroup(with: selectedAppGroup.id) {
            selectedAppGroupIds = [appGroup.id]
        } else {
            selectedAppGroupIds = []
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
            openAppsOnActivation: appGroupTargetApp == AppConstants.lastFocusedOption ? nil : true
        )

        appGroupRepository.updateAppGroup(updatedAppGroup)
        appGroups = appGroupRepository.appGroups
        self.selectedAppGroup = appGroupRepository.findAppGroup(with: selectedAppGroup.id)
    }

    func addAppGroup() {
        // Find a unique name for the new app group
        var counter = 1
        var name = "New App Group"
        while appGroups.contains(where: { $0.name == name }) {
            counter += 1
            name = "New App Group \(counter)"
        }

        appGroupRepository.addAppGroup(name: name)
        appGroups = appGroupRepository.appGroups

        if let newAppGroup = appGroups.last {
            selectedAppGroup = newAppGroup
            editingAppGroupId = newAppGroup.id
            newlyCreatedAppGroupId = newAppGroup.id
        }
    }

    func deleteSelectedAppGroups() {
        guard !selectedAppGroupIds.isEmpty else { return }

        appGroupRepository.deleteAppGroups(ids: selectedAppGroupIds)
        appGroups = appGroupRepository.appGroups
        selectedAppGroupIds = []
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
