import Foundation

typealias RawKeyCode = UInt16
typealias RawKeyModifiers = UInt

struct AppHotKey: Codable, Hashable {
    let value: String

    init(value: String) { self.value = value }

    init(keyCode: RawKeyCode, modifiers: RawKeyModifiers) {
        let keyEquivalent = KeyCodesMap.toString[keyCode] ?? ""
        let modifiers = KeyModifiersMap.toString(modifiers)
        let result = [modifiers, keyEquivalent].filter { !$0.isEmpty }.joined(separator: "+")

        self.init(value: result)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(value: container.decode(String.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
