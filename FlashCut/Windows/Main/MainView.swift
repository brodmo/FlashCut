import AppKit
import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModel()
    @Environment(\.openWindow) var openWindow
    @State private var selectedAppGroups: Set<AppGroup> = []
    @State private var selectedApps: Set<MacApp> = []
    @State private var editingAppGroup: AppGroup?

    private var currentAppGroup: AppGroup? {
        guard selectedAppGroups.count == 1 else { return nil }
        return selectedAppGroups.first
    }

    private var currentApps: [MacApp] {
        currentAppGroup?.apps ?? []
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16.0) {
            appGroups
            rightPanel
        }
        .padding()
        .frame(minWidth: 450, minHeight: 350)
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let appGroup = currentAppGroup {
                AppGroupConfigurationView(
                    appGroup: appGroup,
                    apps: currentApps
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
            List(selection: $selectedAppGroups) {
                ForEach(viewModel.appGroups) { appGroup in
                    AppGroupCell(
                        viewModel: viewModel,
                        appGroup: appGroup,
                        isCurrent: currentAppGroup == appGroup,
                        editOnAppear: editingAppGroup == appGroup,
                        onEditingComplete: { editingAppGroup = nil }
                    )
                    .tag(appGroup)
                }
                .onMove { from, to in
                    viewModel.appGroups.move(fromOffsets: from, toOffset: to)
                }
            }
            .onChange(of: selectedAppGroups) { oldGroups, newGroups in
                // Clear app selection when group selection changes
                if newGroups.count != 1 {
                    selectedApps = []
                }

                // Clear app selection when a new group is selected
                if newGroups.count == 1, let selectedGroup = newGroups.first, selectedGroup != oldGroups.first {
                    selectedApps = []
                }
            }
            .tahoeBorder()

            HStack {
                Button(action: {
                    if let newGroup = viewModel.addAppGroup() {
                        selectedAppGroups = [newGroup]
                        editingAppGroup = newGroup
                    }
                }, label: {
                    Image(systemName: "plus")
                        .frame(height: 16)
                })

                Button(action: {
                    viewModel.deleteAppGroups(selectedAppGroups)
                    selectedAppGroups = []
                }, label: {
                    Image(systemName: "trash")
                        .frame(height: 16)
                })
                .disabled(selectedAppGroups.isEmpty)

                Spacer()
            }
        }
        .frame(width: 200)
    }

    private var assignedApps: some View {
        VStack(alignment: .leading) {
            List(
                currentApps,
                id: \.self,
                selection: $selectedApps
            ) { app in
                AppCell(
                    appGroupId: currentAppGroup?.id ?? UUID(),
                    app: app
                )
            }
            .tahoeBorder()

            HStack {
                Button(action: {
                    if let group = currentAppGroup {
                        viewModel.addApp(to: group)
                    }
                }) {
                    Image(systemName: "plus")
                        .frame(height: 16)
                }.disabled(currentAppGroup == nil)

                Button(action: {
                    if let group = currentAppGroup {
                        viewModel.deleteApps(selectedApps, from: group)
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
