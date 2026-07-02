import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(filter: #Predicate<TodoItem> { !$0.isCompleted },
           sort: \TodoItem.sortOrder)
    private var pendingTodos: [TodoItem]

    @Query(sort: \DailyStats.date, order: .reverse)
    private var recentStats: [DailyStats]

    private var todayStats: DailyStats? {
        recentStats.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: FSSpacing.lg) {
                // Greeting
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date().greeting)
                        .font(FSTypography.displayFallbackMD)
                        .foregroundStyle(FSColors.textPrimary)
                    Text(dateString())
                        .font(FSTypography.uiCaption)
                        .foregroundStyle(FSColors.textSecondary)
                }

                // Stat pills row
                HStack(spacing: 8) {
                    StatPillView(
                        value: "\(todayStats?.tasksCompleted ?? 0)",
                        label: "Tasks"
                    )
                    StatPillView(
                        value: StatsService.formatDurationShort(seconds: todayStats?.totalFocusSeconds ?? 0),
                        label: "Focus"
                    )
                    StatPillView(
                        value: StatsService.todayScreenTime,
                        label: "Screen"
                    )
                }

                // CTA
                CTAButton(title: "Start Flow Session") {}

                // Recent tasks
                VStack(alignment: .leading, spacing: FSSpacing.sm) {
                    SectionLabel(text: "Up Next")

                    VStack(spacing: 0) {
                        ForEach(pendingTodos.prefix(3)) { todo in
                            DashboardTaskRow(todo: todo)
                        }
                    }
                    .cardStyle()
                }

                // Contribution dots
                VStack(alignment: .leading, spacing: FSSpacing.sm) {
                    SectionLabel(text: "This Week")

                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { dayOffset in
                            let intensity = contributionIntensity(for: dayOffset)
                            Circle()
                                .fill(dotColor(for: intensity))
                                .frame(width: 8, height: 8)
                        }
                        Spacer()
                    }
                }
            }
            .screenPadding()
            .padding(.top, FSSpacing.md)
            .padding(.bottom, FSSpacing.md)
        }
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func contributionIntensity(for dayOffset: Int) -> Int {
        let date = Date.daysAgo(6 - dayOffset)
        guard let stats = recentStats.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }) else { return 0 }
        let score = stats.totalFocusSeconds
        switch score {
        case 0: return 0
        case 1..<1800: return 1
        case 1800..<3600: return 2
        case 3600..<5400: return 3
        case 5400..<7200: return 4
        default: return 5
        }
    }

    private func dotColor(for intensity: Int) -> Color {
        switch intensity {
        case 0: FSColors.dotL1
        case 1: FSColors.dotL2
        case 2: FSColors.dotL3
        case 3: FSColors.dotL4
        default: FSColors.dotL5
        }
    }
}

private struct DashboardTaskRow: View {
    let todo: TodoItem

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(FSColors.textMuted, lineWidth: 1.5)
                .frame(width: 16, height: 16)

            Text(todo.title)
                .font(.system(size: 13))
                .foregroundStyle(FSColors.textPrimary)
                .lineLimit(1)

            Spacer()

            if let tag = todo.tag {
                Text(tag)
                    .font(.system(size: 10))
                    .foregroundStyle(FSColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(FSColors.bgCard)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(FSColors.bgCardBorder, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, FSSpacing.md)
        .padding(.vertical, 11)
    }
}
