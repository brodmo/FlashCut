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

    var body: some View {
        HStack(alignment: .top, spacing: 16.0) {
            appGroups
            rightPanel
        }
        .padding()
        .frame(width: 470, height: 460)
        .sheet(isPresented: $viewModel.isInputDialogPresented) {
            InputDialog(
                title: "Enter App Group name:",
                userInput: $viewModel.userInput,
                isPresented: $viewModel.isInputDialogPresented
            )
        }
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            AppGroupConfigurationView(viewModel: viewModel)
                .frame(height: 85)

            if viewModel.selectedAppGroup != nil {
                assignedApps
            }

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
            .frame(width: 200)
        }
    }

    private var appGroups: some View {
        VStack(alignment: .leading) {
            List(
                $viewModel.appGroups,
                id: \.self,
                editActions: .move,
                selection: $viewModel.selectedAppGroups
            ) { $appGroup in
                AppGroupCell(
                    selectedApps: $viewModel.selectedApps,
                    appGroup: $appGroup
                )
            }
            .frame(width: 200, height: 350)
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
    }

    private var assignedApps: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            .frame(width: 200, height: 265)
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
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    MainView()
}
