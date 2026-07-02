import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<HabitDefinition> { $0.isActive })
    private var habits: [HabitDefinition]

    private var todayCompletion: Double {
        guard !habits.isEmpty else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        var completed = 0
        for habit in habits {
            let todayEntry = habit.entries.first {
                Calendar.current.isDate($0.date, inSameDayAs: today)
            }
            if let entry = todayEntry, entry.currentValue >= habit.targetValue {
                completed += 1
            }
        }
        return Double(completed) / Double(habits.count)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: FSSpacing.lg) {
                // Header with completion ring
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Habits")
                            .font(FSTypography.displayFallbackMD)
                            .foregroundStyle(FSColors.textPrimary)
                        Text("\(habits.count) active habits")
                            .font(FSTypography.uiCaption)
                            .foregroundStyle(FSColors.textSecondary)
                    }
                    Spacer()
                    CompletionRingView(progress: todayCompletion)
                }

                // Dot grid heatmap
                VStack(alignment: .leading, spacing: FSSpacing.sm) {
                    SectionLabel(text: "Activity")
                    DotGridView(data: generateHeatmapData())
                }

                // Habit progress bars
                VStack(alignment: .leading, spacing: FSSpacing.sm) {
                    SectionLabel(text: "Today")

                    VStack(spacing: 0) {
                        ForEach(habits) { habit in
                            HabitProgressRow(habit: habit)
                            if habit.id != habits.last?.id {
                                Divider()
                                    .background(FSColors.bgCardBorder)
                                    .padding(.horizontal, FSSpacing.md)
                            }
                        }
                    }
                    .cardStyle()
                }
            }
            .screenPadding()
            .padding(.top, FSSpacing.md)
            .padding(.bottom, FSSpacing.md)
        }
    }

    private func generateHeatmapData() -> [Double] {
        // Generate 70 days of simulated data from habit entries
        (0..<70).map { dayOffset in
            let date = Date.daysAgo(69 - dayOffset)
            var ratio = 0.0
            for habit in habits {
                if habit.entries.contains(where: {
                    Calendar.current.isDate($0.date, inSameDayAs: date) &&
                    $0.currentValue >= habit.targetValue
                }) {
                    ratio += 1.0 / Double(max(habits.count, 1))
                }
            }
            return ratio
        }
    }
}

private struct HabitProgressRow: View {
    let habit: HabitDefinition

    private var todayEntry: HabitEntry? {
        habit.entries.first {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        }
    }

    private var progress: Double {
        guard habit.targetValue > 0 else { return 0 }
        return min((todayEntry?.currentValue ?? 0) / habit.targetValue, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(habit.name)
                    .font(.system(size: 13))
                    .foregroundStyle(FSColors.textPrimary)

                Spacer()

                Text(progressLabel)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(FSColors.textSecondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(FSColors.bgCardBorder)
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(FSColors.textPrimary)
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, FSSpacing.md)
        .padding(.vertical, 12)
    }

    private var progressLabel: String {
        let current = Int(todayEntry?.currentValue ?? 0)
        let target = Int(habit.targetValue)
        if habit.unit.isEmpty {
            return progress >= 1.0 ? "Done" : "Not done"
        }
        return "\(current)/\(target) \(habit.unit)"
    }
}
