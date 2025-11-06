//
//  MainView.swift
//  FlashSpace
//
//  Created by Wojciech Kulik on 19/01/2025.
//

import AppKit
import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModel()
    @Environment(\.openWindow) var openWindow
    @State private var editingAppGroupId: UUID?
    @State private var selectedAppGroupIds: Set<UUID> = []

    var body: some View {
        HStack(alignment: .top, spacing: 16.0) {
            appGroups
            rightPanel
        }
        .padding()
        .frame(minWidth: 450, minHeight: 350)
        .onChange(of: viewModel.newlyCreatedAppGroupId) { newId in
            if let newId {
                // Update the list selection to include the new app group
                selectedAppGroupIds = [newId]

                // Give the view a moment to update before entering edit mode
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    editingAppGroupId = newId
                    viewModel.newlyCreatedAppGroupId = nil
                }
            }
        }
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.selectedAppGroup != nil {
                AppGroupConfigurationView(viewModel: viewModel)
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
                    HStack {
                        AppGroupCell(
                            isEditing: Binding(
                                get: { editingAppGroupId == appGroup.id },
                                set: { if $0 { editingAppGroupId = appGroup.id } else { editingAppGroupId = nil } }
                            ),
                            selectedApps: $viewModel.selectedApps,
                            appGroup: $appGroup
                        )

                        Spacer()

                        if selectedAppGroupIds.contains(appGroup.id) {
                            Button(action: {
                                editingAppGroupId = appGroup.id
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .tag(appGroup.id)
                }
                .onMove { from, to in
                    viewModel.appGroups.move(fromOffsets: from, toOffset: to)
                }
            }
            .onChange(of: selectedAppGroupIds) { newIds in
                viewModel.selectedAppGroups = Set(viewModel.appGroups.filter { newIds.contains($0.id) })
            }
            .tahoeBorder()

            HStack {
                Button(action: viewModel.addAppGroup) {
                    Image(systemName: "plus")
                        .frame(height: 16)
                }

                Button(action: viewModel.deleteSelectedAppGroups) {
                    Image(systemName: "trash")
                        .frame(height: 16)
                }
                .disabled(viewModel.selectedAppGroups.isEmpty)

                Spacer()
            }
        }
        .frame(width: 200)
    }

    private var assignedApps: some View {
        VStack(alignment: .leading) {
            List(
                viewModel.appGroupApps ?? [],
                id: \.self,
                selection: $viewModel.selectedApps
            ) { app in
                AppCell(
                    appGroupId: viewModel.selectedAppGroup?.id ?? UUID(),
                    app: app
                )
            }
            .tahoeBorder()

            HStack {
                Button(action: viewModel.addApp) {
                    Image(systemName: "plus")
                        .frame(height: 16)
                }.disabled(viewModel.selectedAppGroup == nil)

                Button(action: viewModel.deleteSelectedApps) {
                    Image(systemName: "trash")
                        .frame(height: 16)
                }
                .disabled(viewModel.selectedApps.isEmpty)
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
