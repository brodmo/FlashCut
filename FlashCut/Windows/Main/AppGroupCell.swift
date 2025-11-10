//
//  AppGroupCell.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct AppGroupCell: View {
    @ObservedObject var viewModel: MainViewModel
    @State var isTargeted = false
    @State var editedName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @Binding var appGroup: AppGroup
    let isSelected: Bool

    let appGroupManager: AppGroupManager = AppDependencies.shared.appGroupManager
    let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    var body: some View {
        HStack {
            nameField
            Spacer()
            if isSelected {
                editButton
            }
        }
        .onAppear {
            editedName = appGroup.name
            if viewModel.editingAppGroupId == appGroup.id {
                isTextFieldFocused = true
            }
        }
        .onChange(of: isTextFieldFocused) { _, isFocused in
            if isFocused {
                editedName = appGroup.name
                viewModel.editingAppGroupId = appGroup.id
            } else {
                if viewModel.editingAppGroupId == appGroup.id {
                    viewModel.editingAppGroupId = nil
                }
                editedName = appGroup.name
            }
        }
        .onChange(of: appGroup.name) { _, newValue in
            if !isTextFieldFocused {
                editedName = newValue
            }
        }
        .contentShape(Rectangle())
        .dropDestination(
            for: MacAppWithAppGroup.self,
            action: handleDrop,
            isTargeted: { isTargeted = $0 }
        )
    }

    private var nameField: some View {
        TextField("Name", text: $editedName)
            .textFieldStyle(.plain)
            .lineLimit(1)
            .focused($isTextFieldFocused)
            .foregroundColor(
                isTargeted || appGroup.apps.contains(where: \.bundleIdentifier.isEmpty)
                    ? .errorRed
                    : .primary
            )
            .onSubmit {
                isTextFieldFocused = false
                let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = trimmedName.isEmpty ? "(empty)" : trimmedName
                guard finalName != appGroup.name else { return }
                appGroup.name = finalName
                appGroupRepository.updateAppGroup(appGroup)
            }
            .onExitCommand {
                isTextFieldFocused = false
            }
    }

    private var editButton: some View {
        Button(action: {
            isTextFieldFocused = true
        }, label: {
            Image(systemName: "pencil")
                .foregroundColor(.secondary)
                .font(.system(size: 11))
        })
        .buttonStyle(.plain)
    }

    private func handleDrop(_ apps: [MacAppWithAppGroup], _ _: CGPoint) -> Bool {
        guard let sourceAppGroupId = apps.first?.appGroupId else { return false }

        appGroupRepository.moveApps(
            apps.map(\.app),
            from: sourceAppGroupId,
            to: appGroup.id
        )
        viewModel.selectedApps = []

        appGroupManager.activateAppGroupIfActive(sourceAppGroupId)
        appGroupManager.activateAppGroupIfActive(appGroup.id)

        return true
    }
}
