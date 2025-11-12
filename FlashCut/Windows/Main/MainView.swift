import AppKit
import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModel()
    @Environment(\.openWindow) var openWindow
    @State private var selectedAppGroupIds: Set<UUID> = []
    @State private var selectedApps: Set<MacApp> = []

    private var selectedAppGroup: AppGroup? {
        guard selectedAppGroupIds.count == 1, let id = selectedAppGroupIds.first else { return nil }
        return viewModel.getSelectedAppGroup(id: id)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16.0) {
            appGroups
            rightPanel
        }
        .padding()
        .frame(minWidth: 450, minHeight: 350)
        .onChange(of: viewModel.newlyCreatedAppGroupId) { _, newId in
            if let newId {
                selectedAppGroupIds = [newId]
                viewModel.newlyCreatedAppGroupId = nil
            }
        }
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let selectedAppGroup {
                AppGroupConfigurationView(
                    viewModel: viewModel,
                    apps: selectedAppGroup.apps
                )
                .padding(.bottom, 12)
                assignedApps
            } else {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        openWindow(id: "settings")
                    }, label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }).keyboardShortcut(",")
                }
            }
        }
        .frame(width: 200)
    }

    private var appGroups: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedAppGroupIds) {
                ForEach($viewModel.appGroups) { $appGroup in
                    AppGroupCell(
                        viewModel: viewModel,
                        appGroup: $appGroup,
                        isSelected: selectedAppGroupIds.count == 1 && selectedAppGroupIds.contains(appGroup.id)
                    )
                    .tag(appGroup.id)
                }
                .onMove { from, to in
                    viewModel.appGroups.move(fromOffsets: from, toOffset: to)
                }
            }
            .onChange(of: selectedAppGroupIds) { oldIds, newIds in
                // Clear editing if the edited group is no longer selected
                if let editingId = viewModel.editingAppGroupId, !newIds.contains(editingId) {
                    viewModel.editingAppGroupId = nil
                }

                // Clear app selection when group selection changes
                if newIds.count != 1 {
                    selectedApps = []
                }

                // Load form fields when a single group is selected
                if newIds.count == 1, let selectedId = newIds.first, selectedId != oldIds.first {
                    selectedApps = []
                    viewModel.loadSelectedAppGroup(id: selectedId)
                }
            }
            .tahoeBorder()

            HStack {
                Button(action: {
                    if let newId = viewModel.addAppGroup() {
                        selectedAppGroupIds = [newId]
                    }
                }) {
                    Image(systemName: "plus")
                        .frame(height: 16)
                }

                Button(action: {
                    viewModel.deleteAppGroups(ids: selectedAppGroupIds)
                    selectedAppGroupIds = []
                }) {
                    Image(systemName: "trash")
                        .frame(height: 16)
                }
                .disabled(selectedAppGroupIds.isEmpty)

                Spacer()
            }
        }
        .frame(width: 200)
    }

    private var assignedApps: some View {
        VStack(alignment: .leading) {
            List(
                selectedAppGroup?.apps ?? [],
                id: \.self,
                selection: $selectedApps
            ) { app in
                AppCell(
                    appGroupId: selectedAppGroup?.id ?? UUID(),
                    app: app
                )
            }
            .tahoeBorder()

            HStack {
                Button(action: {
                    if let groupId = selectedAppGroup?.id {
                        viewModel.addApp(toGroupId: groupId)
                    }
                }) {
                    Image(systemName: "plus")
                        .frame(height: 16)
                }.disabled(selectedAppGroup == nil)

                Button(action: {
                    if let groupId = selectedAppGroup?.id {
                        viewModel.deleteApps(selectedApps, fromGroupId: groupId)
                        selectedApps = []
                    }
                }) {
                    Image(systemName: "trash")
                        .frame(height: 16)
                }
                .disabled(selectedApps.isEmpty)
                .keyboardShortcut(.delete)

                Spacer()

                Button(action: {
                    openWindow(id: "settings")
                }, label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.primary)
                }).keyboardShortcut(",")
            }
        }
    }
}

#Preview {
    MainView()
}
