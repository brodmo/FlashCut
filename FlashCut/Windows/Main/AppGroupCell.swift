import SwiftUI
import UniformTypeIdentifiers

struct AppGroupCell: View {
    @ObservedObject var viewModel: MainViewModel
    @State var visibleName: String = ""
    @FocusState private var isEditing: Bool
    let appGroup: AppGroup
    let isCurrent: Bool
    let editOnAppear: Bool
    let onEditingComplete: () -> ()

    let appGroupManager: AppGroupManager = AppDependencies.shared.appGroupManager
    let appGroupRepository: AppGroupRepository = AppDependencies.shared.appGroupRepository

    var body: some View {
        HStack(spacing: 4) {
            nameField
            editButton
        }
        .foregroundColor( // broken app indication
            appGroup.apps.contains(where: \.bundleIdentifier.isEmpty) ? .errorRed : .primary
        )
        .modifier(AppGroupDropModifier(handleDrop: handleDrop))
    }

    private var nameField: some View {
        TextField("Name", text: $visibleName)
            .textFieldStyle(.plain)
            .lineLimit(1)
            .fixedSize(horizontal: !isEditing, vertical: false)
            .focused($isEditing)
            .onAppear {
                visibleName = appGroup.name
                // new app group cell is edited immediately
                if editOnAppear {
                    isEditing = true
                }
            }
            .onChange(of: isEditing) { _, editing in
                if !editing { // isEditing is set to false automatically when focus is lost
                    onEditingComplete()
                }
            }
            .onSubmit {
                let trimmedName = visibleName.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = trimmedName.isEmpty ? "(empty)" : trimmedName
                guard finalName != appGroup.name else { return }
                appGroup.name = finalName
                appGroupRepository.save()
                visibleName = finalName
            }
    }

    private var editButton: some View {
        let isVisible = isCurrent && !isEditing
        return Button(action: {
            isEditing = true
        }, label: {
            Image(systemName: "pencil")
                .foregroundColor(.secondary)
                .font(.system(size: 11))
        })
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
    }

    private func handleDrop(_ apps: [MacAppWithAppGroup], _ _: CGPoint) -> Bool {
        guard let sourceAppGroupId = apps.first?.appGroupId,
              sourceAppGroupId != appGroup.id else { return false }

        appGroupRepository.moveApps(
            apps.map(\.app),
            from: sourceAppGroupId,
            to: appGroup.id
        )

        appGroupManager.activateAppGroupIfActive(sourceAppGroupId)
        appGroupManager.activateAppGroupIfActive(appGroup.id)

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
