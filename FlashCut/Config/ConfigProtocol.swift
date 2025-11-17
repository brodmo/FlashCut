import Combine

protocol ConfigProtocol {
    var updatePublisher: AnyPublisher<(), Never> { get }

    func load(from appSettings: Config)
    func update(_ appSettings: inout Config)
}
