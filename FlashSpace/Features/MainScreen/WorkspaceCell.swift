//
//  WorkspaceCell.swift
//
//  Created by Wojciech Kulik on 20/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct AppGroupCell: View {
    @State var isTargeted = false
    @Binding var selectedApps: Set<MacApp>

    let appGroupManager: AppGroupManager = AppDependencies.shared.appGroupManager
    let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    let appGroup: AppGroup

    var body: some View {
        HStack {
            Image(systemName: appGroup.symbolIconName ?? .defaultIconSymbol)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(.secondary)

            Text(appGroup.name)
                .lineLimit(1)
                .foregroundColor(
                    isTargeted || appGroup.apps.contains(where: \.bundleIdentifier.isEmpty)
                        ? .errorRed
                        : .primary
                )
            Spacer()
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
}
