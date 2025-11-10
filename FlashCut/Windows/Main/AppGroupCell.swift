//
//  AppGroupCell.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct AppGroupCell: View {
    @State var isTargeted = false
    @Binding var isEditing: Bool
    @State var editedName: String?
    @FocusState private var isTextFieldFocused: Bool
    @Binding var selectedApps: Set<MacApp>
    @Binding var appGroup: AppGroup
    let isSelected: Bool

    let appGroupManager: AppGroupManager = AppDependencies.shared.appGroupManager
    let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    var body: some View {
        HStack {
            if isEditing {
                editingName
            } else {
                Text(appGroup.name).lineLimit(1)
                    .foregroundColor(
                        isTargeted || appGroup.apps.contains(where: \.bundleIdentifier.isEmpty)
                            ? .errorRed
                            : .primary
                    )
            }
            Spacer()
            if isSelected {
                editButton
            }
        }
        .contentShape(Rectangle())
        .dropDestination(
            for: MacAppWithAppGroup.self,
            action: handleDrop,
            isTargeted: { isTargeted = $0 }
        )
    }

    private var editingName: some View {
        let textBinding = Binding(
            get: { editedName ?? appGroup.name }, // set the default value
            set: { editedName = $0 }
        )
        return TextField("Name", text: textBinding)
            .textFieldStyle(.plain)
            .focused($isTextFieldFocused)
            .task {
                isTextFieldFocused = true
            }
            .onSubmit {
                isEditing = false
                let newName = editedName
                editedName = nil
                guard let newName else { return }

                let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty, trimmedName != appGroup.name else { return }

                appGroup.name = trimmedName
                appGroupRepository.updateAppGroup(appGroup)
            }
            .onExitCommand {
                isEditing = false
                editedName = nil
            }
    }

    private var editButton: some View {
        Button(action: {
            isEditing = true
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
        selectedApps = []

        appGroupManager.activateAppGroupIfActive(sourceAppGroupId)
        appGroupManager.activateAppGroupIfActive(appGroup.id)

        return true
    }
}
