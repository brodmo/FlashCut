import Combine
import Foundation

final class AppGroupSettings: ObservableObject {
    @Published var recentAppGroup: AppHotKey?
    @Published var nextAppInGroup: AppHotKey?
    @Published var previousAppInGroup: AppHotKey?

    private var observer: AnyCancellable?
    private let updateSubject = PassthroughSubject<(), Never>()

    init() { observe() }

    private func observe() {
        observer = Publishers.MergeMany(
            $recentAppGroup.settingsPublisher(),
            $nextAppInGroup.settingsPublisher(),
            $previousAppInGroup.settingsPublisher()
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
        recentAppGroup = appSettings.recentAppGroup
        nextAppInGroup = appSettings.nextAppInGroup
        previousAppInGroup = appSettings.previousAppInGroup
        observe()
    }

    func update(_ appSettings: inout AppSettings) {
        appSettings.recentAppGroup = recentAppGroup
        appSettings.nextAppInGroup = nextAppInGroup
        appSettings.previousAppInGroup = previousAppInGroup
    }
}
