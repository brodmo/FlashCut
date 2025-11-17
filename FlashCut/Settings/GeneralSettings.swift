import Combine
import Foundation

final class GeneralSettings: ObservableObject {
    @Published var checkForUpdatesAutomatically = false {
        didSet { UpdatesManager.shared.autoCheckForUpdates = checkForUpdatesAutomatically }
    }

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = $checkForUpdatesAutomatically.settingsPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateSubject.send() }
    }
}

extension GeneralSettings: ConfigProtocol {
    var updatePublisher: AnyPublisher<(), Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func load(from appSettings: Config) {
        observer = nil
        checkForUpdatesAutomatically = appSettings.checkForUpdatesAutomatically ?? false
        observe()
    }

    func update(_ appSettings: inout Config) {
        appSettings.checkForUpdatesAutomatically = checkForUpdatesAutomatically
    }
}
