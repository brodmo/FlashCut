//
//  Publisher.swift
//
//  Created by Wojciech Kulik on 16/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

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
