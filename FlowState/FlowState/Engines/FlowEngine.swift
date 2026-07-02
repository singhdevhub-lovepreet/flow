import Foundation
import Combine

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    var isChecked: Bool = false
}

enum FlowStage: Equatable {
    case idle
    case prepare(remaining: Int)
    case focus(remaining: Int)
    case release(remaining: Int)
    case rest(remaining: Int)
    case completed

    var label: String {
        switch self {
        case .idle: "Ready"
        case .prepare: "Prepare"
        case .focus: "Focus"
        case .release: "Release"
        case .rest: "Rest"
        case .completed: "Complete"
        }
    }

    var stageIndex: Int {
        switch self {
        case .idle: -1
        case .prepare: 0
        case .focus: 1
        case .release: 2
        case .rest: 3
        case .completed: 4
        }
    }

    var remaining: Int {
        switch self {
        case .idle, .completed: 0
        case .prepare(let r), .focus(let r), .release(let r), .rest(let r): r
        }
    }
}

@Observable
final class FlowEngine {
    var state: FlowStage = .idle
    var checklist: [ChecklistItem] = [
        ChecklistItem(title: "Phone on silent"),
        ChecklistItem(title: "Close distracting apps"),
        ChecklistItem(title: "Water nearby"),
        ChecklistItem(title: "Clear workspace")
    ]

    // Durations in seconds
    let prepareDuration = 120   // 2 min
    let focusDuration = 1200    // 20 min
    let releaseDuration = 180   // 3 min
    let restDuration = 300      // 5 min

    var isRunning: Bool {
        switch state {
        case .idle, .completed: false
        default: true
        }
    }

    var totalDuration: Int {
        switch state {
        case .prepare: prepareDuration
        case .focus: focusDuration
        case .release: releaseDuration
        case .rest: restDuration
        default: 0
        }
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (Double(state.remaining) / Double(totalDuration))
    }

    var breathingRate: Double {
        switch state {
        case .prepare: 6.0
        case .focus: 4.0
        case .release: 8.0
        case .rest: 6.0
        default: 6.0
        }
    }

    private var timer: AnyCancellable?
    var onSessionCompleted: ((FlowSession) -> Void)?

    func start() {
        state = .prepare(remaining: prepareDuration)
        startTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        state = .idle
        resetChecklist()
    }

    func toggleChecklistItem(_ item: ChecklistItem) {
        if let index = checklist.firstIndex(where: { $0.id == item.id }) {
            checklist[index].isChecked.toggle()
        }
    }

    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        switch state {
        case .prepare(let remaining):
            if remaining <= 1 {
                state = .focus(remaining: focusDuration)
            } else {
                state = .prepare(remaining: remaining - 1)
            }
        case .focus(let remaining):
            if remaining <= 1 {
                state = .release(remaining: releaseDuration)
            } else {
                state = .focus(remaining: remaining - 1)
            }
        case .release(let remaining):
            if remaining <= 1 {
                state = .rest(remaining: restDuration)
            } else {
                state = .release(remaining: remaining - 1)
            }
        case .rest(let remaining):
            if remaining <= 1 {
                timer?.cancel()
                timer = nil
                state = .completed
            } else {
                state = .rest(remaining: remaining - 1)
            }
        default:
            break
        }
    }

    private func resetChecklist() {
        checklist = checklist.map { item in
            var copy = item
            copy.isChecked = false
            return copy
        }
    }

    func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
