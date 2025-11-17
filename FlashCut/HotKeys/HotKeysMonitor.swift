import ShortcutRecorder

protocol HotKeysMonitorProtocol: AnyObject {
    var actions: [ShortcutAction] { get }

    func addAction(_ anAction: ShortcutAction, forKeyEvent aKeyEvent: KeyEventType)
    func removeAction(_ anAction: ShortcutAction)
    func removeAllActions()
}

extension GlobalShortcutMonitor: HotKeysMonitorProtocol {}
