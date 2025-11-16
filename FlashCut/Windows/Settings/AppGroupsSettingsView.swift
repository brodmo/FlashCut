import SwiftUI

struct AppGroupsSettingsView: View {
    @StateObject var settings = AppDependencies.shared.appGroupSettings

    var body: some View {
        Form {
            hotkey("Recent App Group", for: $settings.recentAppGroup)
            hotkey("Next App in Group", for: $settings.nextAppInGroup)
            hotkey("Previous App in Group", for: $settings.previousAppInGroup)
        }
        .formStyle(.grouped)
        .navigationTitle("App Groups")
    }
}
