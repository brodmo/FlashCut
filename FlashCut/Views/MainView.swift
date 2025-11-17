import AppKit
import SwiftUI

struct MainView: View {
    @ObservedObject var repository = AppDependencies.shared.appGroupRepository
    @Environment(\.openWindow) var openWindow
    @State private var selectedAppGroups: Set<AppGroup> = []
    @State private var newAppGroup: AppGroup?

    private var currentAppGroup: AppGroup? {
        guard selectedAppGroups.count == 1 else { return nil }
        return selectedAppGroups.first
    }

    private var settingsButton: some View {
        Button(action: {
            openWindow(id: "settings")
        }, label: {
            Image(systemName: "gearshape")
                .foregroundColor(.primary)
        }).keyboardShortcut(",")
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
        VStack {
            if let appGroup = currentAppGroup, appGroup != newAppGroup {
                AppGroupConfigurationView(appGroup: appGroup)
                AppListView(appGroup: appGroup) {
                    settingsButton
                }
            } else {
                Spacer()
                HStack {
                    Spacer()
                    settingsButton
                }
            }
        }
        .frame(width: 200)
    }

    private var appGroups: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedAppGroups) {
                ForEach(repository.appGroups) { appGroup in
                    AppGroupCell(
                        appGroup: appGroup,
                        isCurrent: currentAppGroup == appGroup,
                        isNew: newAppGroup == appGroup,
                        onNewIsDone: {
                            newAppGroup = nil
                            if appGroup.name.isEmpty {
                                selectedAppGroups = []
                                repository.deleteAppGroup(id: appGroup.id)
                            }
                        }
                    )
                    .tag(appGroup)
                }
                .onMove { from, to in
                    repository.reorderAppGroups(from: from, to: to)
                }
            }
            .tahoeBorder()

            HStack {
                Button(action: {
                    let newGroup = AppGroup(name: "")
                    newAppGroup = newGroup
                    repository.addAppGroup(newGroup)
                    // delay selection so cell is properly rendered first
                    DispatchQueue.main.async {
                        selectedAppGroups = [newGroup]
                    }
                }, label: {
                    Image(systemName: "plus")
                        .frame(height: 16)
                })

                Button(action: {
                    repository.deleteAppGroups(selectedAppGroups)
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
}

#Preview {
    MainView()
}
