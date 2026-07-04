import Foundation
import SwiftData
import os

private let log = Logger(subsystem: "com.flowstate.app", category: "StatsService")

enum StatsService {
    /// Mocked screen time value
    static var todayScreenTime: String { "4h 23m" }

    /// Mocked app usage
    static var topApps: [(name: String, minutes: Int)] {
        [
            ("Xcode", 142),
            ("Safari", 67),
            ("Slack", 45),
            ("Figma", 38)
        ]
    }

    static func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    static func formatDurationShort(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }

    // MARK: - DailyStats Management

    /// Get or create today's DailyStats record
    static func todayStats(in context: ModelContext) -> DailyStats {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date == today }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let stats = DailyStats(date: Date())
        context.insert(stats)
        log.info("Created new DailyStats for today")
        return stats
    }

    /// Call when a todo is marked completed
    static func recordTaskCompleted(in context: ModelContext) {
        let stats = todayStats(in: context)
        stats.tasksCompleted += 1
        log.info("Task completed — today total: \(stats.tasksCompleted)")
    }

    /// Call when a completed todo is unmarked (toggled back to incomplete)
    static func recordTaskUncompleted(in context: ModelContext) {
        let stats = todayStats(in: context)
        stats.tasksCompleted = max(0, stats.tasksCompleted - 1)
        log.info("Task uncompleted — today total: \(stats.tasksCompleted)")
    }

    /// Call when a Flow session is saved
    static func recordFlowSession(startedAt: Date, endedAt: Date, in context: ModelContext) {
        let stats = todayStats(in: context)
        let focusSeconds = Int(endedAt.timeIntervalSince(startedAt))
        stats.totalFocusSeconds += max(0, focusSeconds)
        stats.flowSessionsCount += 1
        log.info("Flow session recorded — \(focusSeconds)s focus, today total: \(stats.totalFocusSeconds)s")
    }

    /// Call when a Pomodoro session is saved
    static func recordPomodoroSession(sessionsCompleted: Int, focusDuration: Int, in context: ModelContext) {
        let stats = todayStats(in: context)
        let focusSeconds = sessionsCompleted * focusDuration
        stats.totalFocusSeconds += focusSeconds
        stats.pomodoroSessionsCount += 1
        log.info("Pomodoro session recorded — \(focusSeconds)s focus, today total: \(stats.totalFocusSeconds)s")
    }
}
