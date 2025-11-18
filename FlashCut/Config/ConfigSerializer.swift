import Foundation
import Yams

enum ConfigSerializer {
    static let configDirectory = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/flashcut")

    static func serialize(filename: String, _ value: some Encodable) throws {
        let url = getUrl(for: filename)
        let data = try encoder.encode(value)

        do {
            try url.createIntermediateDirectories()
        } catch {
            Logger.log("Failed to create config directory: \(error)")
            throw error
        }

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
    static let encoder: ConfigEncoder = YAMLEncoder()
    static let decoder: ConfigDecoder = YAMLDecoder()

    static func getUrl(for filename: String) -> URL {
        configDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension("yaml")
    }
}

// MARK: - Config Encoder/Decoder Protocols

protocol ConfigEncoder {
    func encode(_ value: some Encodable) throws -> Data
}

protocol ConfigDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable
}

// MARK: - YAML Conformance

extension YAMLEncoder: ConfigEncoder {
    func encode(_ value: some Encodable) throws -> Data {
        let yaml: String = try encode(value)
        return yaml.data(using: .utf8) ?? Data()
    }
}

extension YAMLDecoder: ConfigDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        let yaml = String(data: data, encoding: .utf8) ?? ""
        return try decode(T.self, from: yaml)
    }
}
