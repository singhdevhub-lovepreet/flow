import Foundation

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
}
