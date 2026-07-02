import AppKit
import SwiftUI
import SwiftData

final class PanelController {
    private let panel: NotchPanel
    private var resignObserver: Any?
    private let modelContainer: ModelContainer
    private let flowEngine: FlowEngine
    private let pomodoroEngine: PomodoroEngine

    var isVisible: Bool { panel.isVisible }

    init(modelContainer: ModelContainer, flowEngine: FlowEngine, pomodoroEngine: PomodoroEngine) {
        self.modelContainer = modelContainer
        self.flowEngine = flowEngine
        self.pomodoroEngine = pomodoroEngine
        self.panel = NotchPanel()

        let rootView = RootView()
            .environment(flowEngine)
            .environment(pomodoroEngine)
            .modelContainer(modelContainer)

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = panel.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(hostingView)

        resignObserver = NotificationCenter.default.addObserver(
            forName: .panelDidResignKey,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            // Don't dismiss if a timer is running and user might need it
            self?.hide()
        }
    }

    deinit {
        if let observer = resignObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func toggle(relativeTo statusItem: NSStatusItem) {
        if panel.isVisible {
            hide()
        } else {
            show(relativeTo: statusItem)
        }
    }

    func showQuickAdd(relativeTo statusItem: NSStatusItem) {
        NotificationCenter.default.post(name: .quickAddRequested, object: nil)
        if !panel.isVisible {
            show(relativeTo: statusItem)
        }
    }

    func show(relativeTo statusItem: NSStatusItem) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let panelWidth: CGFloat = 440
        let panelHeight: CGFloat = 540

        // Center horizontally, position 8px below menu bar
        let menuBarHeight = NSStatusBar.system.thickness
        let x = (screenFrame.width - panelWidth) / 2
        let y = screenFrame.height - menuBarHeight - panelHeight - 8

        let targetFrame = NSRect(x: x, y: y, width: panelWidth, height: panelHeight)

        // Start 12px above target for drop-down effect
        let startFrame = NSRect(x: x, y: y + 12, width: panelWidth, height: panelHeight)

        panel.setFrame(startFrame, display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
            panel.animator().setFrame(targetFrame, display: true)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard panel.isVisible else { return }

        let currentFrame = panel.frame
        let targetFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y + 6,
            width: currentFrame.width,
            height: currentFrame.height
        )

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(targetFrame, display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
        })
    }
}
