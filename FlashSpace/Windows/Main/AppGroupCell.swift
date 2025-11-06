//
//  AppGroupCell.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

private struct IsSelectedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isRowSelected: Bool {
        get { self[IsSelectedKey.self] }
        set { self[IsSelectedKey.self] = newValue }
    }
}

struct AppGroupCell: View {
    @State var isTargeted = false
    @State var isEditing = false
    @State var editedName = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.isRowSelected) private var isSelected
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

                if isSelected {
                    Button(action: {
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
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
        guard !trimmedName.isEmpty, trimmedName != appGroup.name else { return }

        var updatedAppGroup = appGroup
        updatedAppGroup.name = trimmedName
        appGroupRepository.updateAppGroup(updatedAppGroup)
    }
}
