import ShortcutRecorder

extension AppHotKey {
    func toShortcut() -> Shortcut? {
        let components = value.components(separatedBy: "+")
        let modifiers = KeyModifiersMap.toModifiers(value)

        guard let keyEquivalent = components.last,
              let rawKeyCode = KeyCodesMap[keyEquivalent],
              let keyCode = KeyCode(rawValue: rawKeyCode) else { return nil }

        return Shortcut(
            code: keyCode,
            modifierFlags: NSEvent.ModifierFlags(rawValue: modifiers),
            characters: nil,
            charactersIgnoringModifiers: nil
        )
    }
}
