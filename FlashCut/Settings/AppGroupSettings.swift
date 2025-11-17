import Combine
import Foundation

final class AppGroupSettings: ObservableObject {
    @Published var lastAppGroup: AppHotKey?
    @Published var cycleAppsInGroup: AppHotKey?

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $lastAppGroup.settingsPublisher(),
            $cycleAppsInGroup.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension AppGroupSettings: SettingsProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: AppSettings) {
        observer = nil
        lastAppGroup = appSettings.lastAppGroup
        cycleAppsInGroup = appSettings.cycleAppsInGroup
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.lastAppGroup = lastAppGroup
        appSettings.cycleAppsInGroup = cycleAppsInGroup
    }
}
