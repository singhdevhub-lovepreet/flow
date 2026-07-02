import Foundation
import SwiftData

@Model
final class PomodoroSession {
    var startedAt: Date
    var endedAt: Date?
    var focusDuration: Int
    var breakDuration: Int
    var sessionsCompleted: Int
    var totalSessions: Int
    var wasCompleted: Bool

    init(focusDuration: Int = 1500, breakDuration: Int = 300, totalSessions: Int = 4) {
        self.startedAt = Date()
        self.endedAt = nil
        self.focusDuration = focusDuration
        self.breakDuration = breakDuration
        self.sessionsCompleted = 0
        self.totalSessions = totalSessions
        self.wasCompleted = false
    }
}
