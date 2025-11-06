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
    @State var editedName = ""
    @FocusState private var isTextFieldFocused: Bool
    @Binding var selectedApps: Set<MacApp>
    @Binding var appGroup: AppGroup

    let appGroupManager: AppGroupManager = AppDependencies.shared.appGroupManager
    let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    var body: some View {
        HStack {
            if isEditing {
                TextField("Name", text: $editedName)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        editedName = appGroup.name
                        isTextFieldFocused = true
                    }
                    .onSubmit {
                        saveName()
                    }
                    .onExitCommand {
                        isEditing = false
                    }
            } else {
                Text(appGroup.name)
                    .lineLimit(1)
                    .foregroundColor(
                        isTargeted || appGroup.apps.contains(where: \.bundleIdentifier.isEmpty)
                            ? .errorRed
                            : .primary
                    )

                Spacer()
            }
        }
        .onChange(of: isEditing) { newValue in
            if newValue {
                editedName = appGroup.name
                // Small delay to ensure TextField is rendered before focusing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isTextFieldFocused = true
                }
            }
        }
        .contentShape(Rectangle())
        .dropDestination(for: MacAppWithAppGroup.self) { apps, _ in
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
        } isTargeted: {
            isTargeted = $0
        }
    }

    private func saveName() {
        isEditing = false
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)

        // If empty, use a default name
        let finalName = trimmedName.isEmpty ? "(empty)" : trimmedName

        // Only update if the name has changed
        guard finalName != appGroup.name else { return }

        var updatedAppGroup = appGroup
        updatedAppGroup.name = finalName

        // Update both the binding and the repository
        appGroup = updatedAppGroup
        appGroupRepository.updateAppGroup(updatedAppGroup)
    }
}
