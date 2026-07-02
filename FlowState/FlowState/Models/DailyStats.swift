import Foundation
import SwiftData

@Model
final class DailyStats {
    @Attribute(.unique) var date: Date
    var totalFocusSeconds: Int
    var tasksCompleted: Int
    var habitsCompletedRatio: Double
    var flowSessionsCount: Int
    var pomodoroSessionsCount: Int

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.totalFocusSeconds = 0
        self.tasksCompleted = 0
        self.habitsCompletedRatio = 0
        self.flowSessionsCount = 0
        self.pomodoroSessionsCount = 0
    }
}
