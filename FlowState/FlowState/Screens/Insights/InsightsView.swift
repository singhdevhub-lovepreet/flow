import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \DailyStats.date, order: .reverse)
    private var allStats: [DailyStats]

    private var weekStats: [DailyStats] {
        Array(allStats.prefix(7))
    }

    private var totalFocusThisWeek: Int {
        weekStats.reduce(0) { $0 + $1.totalFocusSeconds }
    }

    private var totalTasksThisWeek: Int {
        weekStats.reduce(0) { $0 + $1.tasksCompleted }
    }

    private var totalSessionsThisWeek: Int {
        weekStats.reduce(0) { $0 + $1.flowSessionsCount + $1.pomodoroSessionsCount }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: FSSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Insights")
                        .font(FSTypography.displayFallbackMD)
                        .foregroundStyle(FSColors.textPrimary)
                    Text("This week's summary")
                        .font(FSTypography.uiCaption)
                        .foregroundStyle(FSColors.textSecondary)
                }

                // Stat callout
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(StatsService.formatDuration(seconds: totalFocusThisWeek))
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(FSColors.textPrimary)
                    Text("focus time")
                        .font(.system(size: 16))
                        .foregroundStyle(FSColors.textMuted)
                }

                // Stat pills
                HStack(spacing: 8) {
                    StatPillView(value: "\(totalTasksThisWeek)", label: "Tasks")
                    StatPillView(value: "\(totalSessionsThisWeek)", label: "Sessions")
                    StatPillView(
                        value: String(format: "%.0f%%", averageHabitCompletion * 100),
                        label: "Habits"
                    )
                }

                // Bar chart — daily focus
                VStack(alignment: .leading, spacing: FSSpacing.sm) {
                    SectionLabel(text: "Daily Focus")

                    BarChartView(
                        data: chartData,
                        highlightIndex: chartData.count - 1
                    )
                    .cardStyle()
                    .padding(.vertical, FSSpacing.sm)
                }

                // Heatmap
                VStack(alignment: .leading, spacing: FSSpacing.sm) {
                    SectionLabel(text: "Activity Heatmap")

                    heatmapView
                }

                // Leaderboard (mocked)
                VStack(alignment: .leading, spacing: FSSpacing.sm) {
                    SectionLabel(text: "Top Focus Days")

                    VStack(spacing: 0) {
                        ForEach(topDays.indices, id: \.self) { index in
                            leaderboardRow(rank: index + 1, stats: topDays[index])
                            if index < topDays.count - 1 {
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

    private var averageHabitCompletion: Double {
        guard !weekStats.isEmpty else { return 0 }
        return weekStats.reduce(0.0) { $0 + $1.habitsCompletedRatio } / Double(weekStats.count)
    }

    private var chartData: [(label: String, value: Double)] {
        let sorted = weekStats.sorted { $0.date < $1.date }
        let maxFocus = sorted.map(\.totalFocusSeconds).max() ?? 1
        return sorted.map { stat in
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let label = formatter.string(from: stat.date)
            let value = maxFocus > 0 ? Double(stat.totalFocusSeconds) / Double(maxFocus) : 0
            return (label: label, value: value)
        }
    }

    private var heatmapView: some View {
        let columns = Array(repeating: GridItem(.fixed(22), spacing: 3), count: 12)
        let data = generateHeatmapData()

        return LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<48, id: \.self) { index in
                let intensity = index < data.count ? data[index] : 0.0
                RoundedRectangle(cornerRadius: 3)
                    .fill(heatmapColor(for: intensity))
                    .aspectRatio(2.5, contentMode: .fit)
            }
        }
    }

    private func generateHeatmapData() -> [Double] {
        (0..<48).map { dayOffset in
            let date = Date.daysAgo(47 - dayOffset)
            if let stat = allStats.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                return min(Double(stat.totalFocusSeconds) / 7200.0, 1.0)
            }
            return 0
        }
    }

    private func heatmapColor(for intensity: Double) -> Color {
        switch intensity {
        case 0: FSColors.dotL1
        case 0.01..<0.25: FSColors.dotL2
        case 0.25..<0.5: FSColors.dotL3
        case 0.5..<0.75: FSColors.dotL4
        default: FSColors.dotL5
        }
    }

    private var topDays: [DailyStats] {
        Array(allStats.sorted { $0.totalFocusSeconds > $1.totalFocusSeconds }.prefix(3))
    }

    private func leaderboardRow(rank: Int, stats: DailyStats) -> some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(rank == 1 ? FSColors.textPrimary : FSColors.textMuted)
                .frame(width: 28)

            let formatter = DateFormatter()
            let _ = formatter.dateFormat = "MMM d"
            Text(formatter.string(from: stats.date))
                .font(.system(size: 13))
                .foregroundStyle(FSColors.textPrimary)

            Spacer()

            Text(StatsService.formatDuration(seconds: stats.totalFocusSeconds))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(FSColors.textSecondary)
        }
        .padding(.horizontal, FSSpacing.md)
        .padding(.vertical, 11)
    }
}
