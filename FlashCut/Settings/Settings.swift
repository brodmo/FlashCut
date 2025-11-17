import Combine
import Foundation

final class Settings: ObservableObject {
    // General
    @Published var checkForUpdatesAutomatically = false {
        didSet { UpdatesManager.shared.autoCheckForUpdates = checkForUpdatesAutomatically }
    }

    // App Groups
    @Published var lastAppGroup: AppHotKey?
    @Published var cycleAppsInGroup: AppHotKey?

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $checkForUpdatesAutomatically.settingsPublisher(),
            $lastAppGroup.settingsPublisher(),
            $cycleAppsInGroup.settingsPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.updateSubject.send() }
    }

    func load(from config: Config) {
        observer = nil
        checkForUpdatesAutomatically = config.checkForUpdatesAutomatically ?? false
        lastAppGroup = config.lastAppGroup
        cycleAppsInGroup = config.cycleAppsInGroup
        observe()
    }

    func update(_ config: inout Config) {
        config.checkForUpdatesAutomatically = checkForUpdatesAutomatically
        config.lastAppGroup = lastAppGroup
        config.cycleAppsInGroup = cycleAppsInGroup
    }
}
