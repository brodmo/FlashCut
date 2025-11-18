import SwiftUI
import UniformTypeIdentifiers

struct AppGroupCell: View {
    @State var visibleName: String = ""
    @FocusState private var isEditing: Bool
    let appGroup: AppGroup
    let isCurrent: Bool
    let isNew: Bool
    let onNewIsDone: () -> ()

    let appGroupManager: AppGroupManager = AppDependencies.shared.appGroupManager
    let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    private var hasInvalidApps: Bool {
        appGroup.apps.contains(where: \.bundleIdentifier.isEmpty)
    }

    var body: some View {
        HStack(spacing: 4) {
            nameField
            if isCurrent, !isNew, !isEditing {
                editButton
            }
        }
        .foregroundColor(hasInvalidApps ? .errorRed : .primary)
        .modifier(AppGroupDropModifier(handleDrop: handleDrop))
    }

    private var nameField: some View {
        TextField("Name", text: $visibleName)
            .textFieldStyle(.plain)
            .lineLimit(1)
            .fixedSize(horizontal: !isEditing, vertical: false)
            .focused($isEditing)
            .opacity(isNew && !isEditing ? 0 : 1)
            .onAppear {
                visibleName = appGroup.name
                if isNew {
                    // delay editing to sync with selection
                    DispatchQueue.main.async {
                        isEditing = true
                    }
                }
            }
            .onChange(of: isEditing) { oldValue, _ in
                // if we were editing a new group
                if oldValue, isNew {
                    onNewIsDone()
                }
            }
            .onSubmit {
                let name = visibleName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, name != appGroup.name else { return }
                appGroup.name = name
                appGroupRepository.save() // New app groups are saved to disk here, not before
                visibleName = name
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
        guard let sourceAppGroupId = apps.first?.appGroupId,
              sourceAppGroupId != appGroup.id else { return false }

        appGroupRepository.moveApps(
            apps.map(\.app),
            from: sourceAppGroupId,
            to: appGroup.id
        )

        return true
    }
}

struct AppGroupDropModifier: ViewModifier {
    let handleDrop: ([MacAppWithAppGroup], CGPoint) -> Bool
    @State var isTargeted: Bool = false

    func body(content: Content) -> some View {
        HStack {
            content
            Spacer() // Make sure the drop target extends all the way
        }
        .dropDestination(
            for: MacAppWithAppGroup.self,
            action: handleDrop,
            isTargeted: { isTargeted = $0 }
        )
        .listRowBackground(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.2))
                .padding(.horizontal, 10) // match list selection styling
                .opacity(isTargeted ? 1 : 0)
        )
    }
}
