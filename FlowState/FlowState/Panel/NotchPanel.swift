import AppKit

final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 540),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Rounded corners
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 20
        contentView?.layer?.masksToBounds = true
        contentView?.layer?.backgroundColor = NSColor.black.cgColor
        contentView?.layer?.borderColor = NSColor(white: 0.1, alpha: 1).cgColor
        contentView?.layer?.borderWidth = 1
    }

    override func resignKey() {
        super.resignKey()
        // Notify panel controller to dismiss
        NotificationCenter.default.post(name: .panelDidResignKey, object: self)
    }
}

extension Notification.Name {
    static let panelDidResignKey = Notification.Name("panelDidResignKey")
    static let quickAddRequested = Notification.Name("quickAddRequested")
    static let quickAddHotkeyFired = Notification.Name("quickAddHotkeyFired")
}
