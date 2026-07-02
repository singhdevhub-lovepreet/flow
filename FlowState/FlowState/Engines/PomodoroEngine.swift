import Foundation
import Combine

indirect enum PomodoroState: Equatable {
    case idle
    case focusing(remaining: Int)
    case breaking(remaining: Int)
    case longBreak(remaining: Int)
    case paused(previousState: PomodoroState)
    case completed

    var label: String {
        switch self {
        case .idle: "Ready"
        case .focusing: "Focus"
        case .breaking: "Break"
        case .longBreak: "Long Break"
        case .paused: "Paused"
        case .completed: "Done"
        }
    }

    var remaining: Int {
        switch self {
        case .idle, .completed: 0
        case .focusing(let r), .breaking(let r), .longBreak(let r): r
        case .paused(let prev): prev.remaining
        }
    }

    static func == (lhs: PomodoroState, rhs: PomodoroState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.completed, .completed): true
        case (.focusing(let a), .focusing(let b)): a == b
        case (.breaking(let a), .breaking(let b)): a == b
        case (.longBreak(let a), .longBreak(let b)): a == b
        case (.paused(let a), .paused(let b)): a == b
        default: false
        }
    }
}

@Observable
final class PomodoroEngine {
    var state: PomodoroState = .idle
    var currentSession: Int = 1
    var sessionsCompleted: Int = 0
    let totalSessions: Int = 4

    let focusDuration = 1500    // 25 min
    let breakDuration = 300     // 5 min
    let longBreakDuration = 900 // 15 min

    var isRunning: Bool {
        switch state {
        case .focusing, .breaking, .longBreak: true
        default: false
        }
    }

    var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    var totalDurationForCurrentPhase: Int {
        switch state {
        case .focusing: focusDuration
        case .breaking: breakDuration
        case .longBreak: longBreakDuration
        case .paused(let prev):
            switch prev {
            case .focusing: focusDuration
            case .breaking: breakDuration
            case .longBreak: longBreakDuration
            default: 0
            }
        default: 0
        }
    }

    var progress: Double {
        guard totalDurationForCurrentPhase > 0 else { return 0 }
        return 1.0 - (Double(state.remaining) / Double(totalDurationForCurrentPhase))
    }

    private var timer: AnyCancellable?
    var onSessionCompleted: ((PomodoroSession) -> Void)?

    func start() {
        currentSession = 1
        sessionsCompleted = 0
        state = .focusing(remaining: focusDuration)
        startTimer()
    }

    func pause() {
        guard isRunning else { return }
        timer?.cancel()
        timer = nil
        state = .paused(previousState: state)
    }

    func resume() {
        guard case .paused(let previousState) = state else { return }
        state = previousState
        startTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        state = .idle
        currentSession = 1
        sessionsCompleted = 0
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
        case .focusing(let remaining):
            if remaining <= 1 {
                sessionsCompleted += 1
                if sessionsCompleted >= totalSessions {
                    state = .longBreak(remaining: longBreakDuration)
                } else {
                    state = .breaking(remaining: breakDuration)
                }
            } else {
                state = .focusing(remaining: remaining - 1)
            }
        case .breaking(let remaining):
            if remaining <= 1 {
                currentSession += 1
                state = .focusing(remaining: focusDuration)
            } else {
                state = .breaking(remaining: remaining - 1)
            }
        case .longBreak(let remaining):
            if remaining <= 1 {
                timer?.cancel()
                timer = nil
                state = .completed
            } else {
                state = .longBreak(remaining: remaining - 1)
            }
        default:
            break
        }
    }

    func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
