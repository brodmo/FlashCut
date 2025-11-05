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
            return try migrateFromJSON(type, filename: filename)
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(type, from: data)
        } catch {
            Logger.log("Failed to deserialize \(filename): \(error)")
            throw error
        }
    }

    private static func migrateFromJSON<T>(_ type: T.Type, filename: String) throws -> T? where T: Codable {
        let jsonUrl = configDirectory.appendingPathComponent("\(filename).json")
        guard FileManager.default.fileExists(atPath: jsonUrl.path) else { return nil }

        Logger.log("Migrating \(filename) from JSON to TOML...")

        let jsonData = try Data(contentsOf: jsonUrl)
        let value = try JSONDecoder().decode(type, from: jsonData)

        // Save as TOML
        try serialize(filename: filename, value)

        // Backup old JSON
        let timestamp = Int(Date().timeIntervalSince1970)
        try? FileManager.default.moveItem(
            at: jsonUrl,
            to: configDirectory.appendingPathComponent("\(filename)-backup-\(timestamp).json")
        )

        Logger.log("Migrated \(filename) from JSON to TOML")
        return value
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
