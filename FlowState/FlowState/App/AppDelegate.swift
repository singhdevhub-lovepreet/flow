import AppKit
import SwiftUI
import SwiftData
import Carbon
import os

private let log = Logger(subsystem: "com.flowstate.app", category: "AppDelegate")

private func carbonHotKeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    NotificationCenter.default.post(name: .quickAddHotkeyFired, object: nil)
    return noErr
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panelController: PanelController!

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            TodoItem.self,
            HabitDefinition.self,
            HabitEntry.self,
            FlowSession.self,
            PomodoroSession.self,
            DailyStats.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    private let flowEngine = FlowEngine()
    private let pomodoroEngine = PomodoroEngine()
    private let claudeService = ClaudeService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.hexagongrid.fill", accessibilityDescription: "FlowState")
            button.action = #selector(togglePanel)
            button.target = self
        }

        panelController = PanelController(
            modelContainer: modelContainer,
            flowEngine: flowEngine,
            pomodoroEngine: pomodoroEngine,
            claudeService: claudeService
        )

        registerGlobalHotkey()
    }

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var hotKeyObserver: Any?

    @objc private func togglePanel() {
        panelController.toggle(relativeTo: statusItem)
    }

    private func registerGlobalHotkey() {
        // Install Carbon event handler for global hotkey (no Accessibility permissions needed)
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotKeyHandler,
            1,
            &eventType,
            nil,
            &handlerRef
        )

        if handlerStatus != noErr {
            log.error("Failed to install Carbon event handler: \(handlerStatus)")
            return
        }

        // Register Option+Space as the global hotkey (like Macatron)
        var hotKeyID = EventHotKeyID(
            signature: OSType(0x464C4F57), // "FLOW"
            id: 1
        )

        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            log.error("Failed to register hotkey (Option+Space): \(registerStatus)")
        } else {
            log.info("Global hotkey registered: Option+Space")
        }

        // Bridge Carbon callback → MainActor via notification
        hotKeyObserver = NotificationCenter.default.addObserver(
            forName: .quickAddHotkeyFired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.panelController.isVisible {
                self.panelController.hide()
            } else {
                self.panelController.showQuickAdd(relativeTo: self.statusItem)
            }
        }
    }

}
