import Combine
import Foundation

extension Publisher where Output: Equatable {
    func settingsPublisher() -> AnyPublisher<(), Failure> {
        removeDuplicates()
            .map { _ in }
            .dropFirst()
            .eraseToAnyPublisher()
    }
}
