//
//  ConfigSerializer.swift
//
//  Created by Wojciech Kulik on 15/02/2025.
//  Copyright © 2025 Wojciech Kulik. All rights reserved.
//

import Foundation
import TOMLKit

enum ConfigSerializer {
    static let configDirectory = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/flashcut")

    static func serialize(filename: String, _ value: some Encodable) throws {
        let url = getUrl(for: filename)
        let data = try encoder.encode(value)
        try? url.createIntermediateDirectories()
        try data.write(to: url)
    }

    static func deserialize<T>(_ type: T.Type, filename: String) throws -> T? where T: Decodable {
        let url = getUrl(for: filename)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(type, from: data)
        } catch {
            Logger.log("Failed to deserialize \(filename): \(error)")
            throw error
        }
    }
}

private extension ConfigSerializer {
    static let encoder: ConfigEncoder = TOMLEncoder()
    static let decoder: ConfigDecoder = TOMLDecoder()

    static func getUrl(for filename: String) -> URL {
        configDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension("toml")
    }
}
