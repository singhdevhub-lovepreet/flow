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

        // Frosted glass background
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.appearance = NSAppearance(named: .darkAqua)
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 20
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.borderColor = NSColor(white: 0.3, alpha: 0.2).cgColor
        visualEffect.layer?.borderWidth = 1
        contentView = visualEffect
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
