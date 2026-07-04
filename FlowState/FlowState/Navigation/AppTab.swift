import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard
    case todos
    case habits
    case flow
    case pomodoro
    case insights
    case mcps

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .todos: "checkmark.circle"
        case .habits: "chart.dots.scatter"
        case .flow: "wind"
        case .pomodoro: "timer"
        case .insights: "chart.bar"
        case .mcps: "server.rack"
        }
    }

    var label: String {
        switch self {
        case .dashboard: "Dashboard"
        case .todos: "Todos"
        case .habits: "Habits"
        case .flow: "Flow"
        case .pomodoro: "Pomodoro"
        case .insights: "Insights"
        case .mcps: "MCPs"
        }
    }
}
