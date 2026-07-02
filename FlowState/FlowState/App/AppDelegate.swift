import AppKit
import SwiftUI
import SwiftData

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
            pomodoroEngine: pomodoroEngine
        )

        seedSampleDataIfNeeded()
    }

    @objc private func togglePanel() {
        panelController.toggle(relativeTo: statusItem)
    }

    private func seedSampleDataIfNeeded() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<TodoItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // Seed todos
        let todos = [
            TodoItem(title: "Review design mockups", tag: "Design", sortOrder: 0),
            TodoItem(title: "Refactor auth module", tag: "Code", sortOrder: 1),
            TodoItem(title: "Update API documentation", tag: "Work", sortOrder: 2),
            TodoItem(title: "Fix navigation transitions", tag: "Code", sortOrder: 3),
            TodoItem(title: "Team standup notes", tag: "Work", sortOrder: 4)
        ]
        // Mark first one as completed
        todos[0].isCompleted = true
        todos[0].completedAt = Date()
        todos.forEach { context.insert($0) }

        // Seed habits
        let meditate = HabitDefinition(name: "Meditate", targetValue: 10, unit: "min")
        let read = HabitDefinition(name: "Read", targetValue: 30, unit: "min")
        let exercise = HabitDefinition(name: "Exercise", targetValue: 1, unit: "")
        [meditate, read, exercise].forEach { context.insert($0) }

        // Seed some habit entries for the past week
        let calendar = Calendar.current
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let normalizedDate = calendar.startOfDay(for: date)

            let meditateEntry = HabitEntry(date: normalizedDate, currentValue: Double.random(in: 5...10))
            meditateEntry.habit = meditate
            context.insert(meditateEntry)

            let readEntry = HabitEntry(date: normalizedDate, currentValue: Double.random(in: 10...30))
            readEntry.habit = read
            context.insert(readEntry)

            if Bool.random() {
                let exerciseEntry = HabitEntry(date: normalizedDate, currentValue: 1)
                exerciseEntry.habit = exercise
                context.insert(exerciseEntry)
            }
        }

        // Seed daily stats for the past week
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let normalizedDate = calendar.startOfDay(for: date)
            let stats = DailyStats(date: normalizedDate)
            stats.totalFocusSeconds = Int.random(in: 1800...7200)
            stats.tasksCompleted = Int.random(in: 1...6)
            stats.habitsCompletedRatio = Double.random(in: 0.3...1.0)
            stats.flowSessionsCount = Int.random(in: 0...3)
            stats.pomodoroSessionsCount = Int.random(in: 0...4)
            context.insert(stats)
        }

        try? context.save()
    }
}
