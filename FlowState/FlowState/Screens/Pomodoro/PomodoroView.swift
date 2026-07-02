import SwiftUI
import SwiftData

struct PomodoroView: View {
    @Environment(PomodoroEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: FSSpacing.lg) {
                if engine.isRunning || engine.isPaused {
                    activeView
                } else if engine.state == .completed {
                    completedView
                } else {
                    idleView
                }
            }
            .screenPadding()
            .padding(.top, FSSpacing.md)
            .padding(.bottom, FSSpacing.md)
        }
    }

    // MARK: - Idle state
    private var idleView: some View {
        VStack(alignment: .leading, spacing: FSSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pomodoro")
                    .font(FSTypography.displayFallbackMD)
                    .foregroundStyle(FSColors.textPrimary)
                Text("25 min focus / 5 min break")
                    .font(FSTypography.uiCaption)
                    .foregroundStyle(FSColors.textSecondary)
            }

            // Ghosted timer preview
            GhostedTimerView(time: "25:00", ghostTime: "25:00")
                .frame(maxWidth: .infinity)

            // Session dots
            sessionDotsView

            CTAButton(title: "Start Focus") {
                engine.start()
            }
        }
    }

    // MARK: - Active state
    private var activeView: some View {
        VStack(spacing: FSSpacing.lg) {
            // State label
            Text(engine.state.label)
                .font(FSTypography.uiLabel)
                .foregroundStyle(FSColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            // Timer
            GhostedTimerView(
                time: engine.formattedTime(engine.state.remaining),
                ghostTime: engine.formattedTime(engine.totalDurationForCurrentPhase)
            )
            .frame(maxWidth: .infinity)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(FSColors.bgCardBorder)
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(FSColors.textPrimary)
                        .frame(width: geo.size.width * engine.progress, height: 3)
                        .animation(.linear(duration: 1), value: engine.progress)
                }
            }
            .frame(height: 3)

            // Session dots
            sessionDotsView

            // Controls
            HStack(spacing: 12) {
                CTAButton(title: "Stop", isPrimary: false) {
                    saveSession()
                    engine.stop()
                }

                if engine.isPaused {
                    CTAButton(title: "Resume") {
                        engine.resume()
                    }
                } else {
                    CTAButton(title: "Pause", isPrimary: false) {
                        engine.pause()
                    }
                }
            }

            // Break card (when on break)
            if case .breaking = engine.state {
                breakCard
            } else if case .longBreak = engine.state {
                breakCard
            }
        }
    }

    // MARK: - Completed state
    private var completedView: some View {
        VStack(spacing: FSSpacing.lg) {
            Text("All sessions complete")
                .font(FSTypography.displayFallbackMD)
                .foregroundStyle(FSColors.textPrimary)

            sessionDotsView

            HStack(spacing: 8) {
                StatPillView(value: "\(engine.sessionsCompleted)", label: "Sessions")
                StatPillView(
                    value: StatsService.formatDurationShort(
                        seconds: engine.sessionsCompleted * engine.focusDuration
                    ),
                    label: "Focus"
                )
            }

            CTAButton(title: "Done") {
                saveSession()
                engine.stop()
            }
        }
    }

    // MARK: - Shared components
    private var sessionDotsView: some View {
        HStack(spacing: 8) {
            ForEach(1...engine.totalSessions, id: \.self) { session in
                Circle()
                    .fill(session <= engine.sessionsCompleted ? FSColors.textPrimary : FSColors.textMuted)
                    .frame(width: 8, height: 8)
            }
            Spacer()
            Text("Session \(engine.currentSession) of \(engine.totalSessions)")
                .font(.system(size: 11))
                .foregroundStyle(FSColors.textMuted)
        }
    }

    private var breakCard: some View {
        HStack(spacing: 12) {
            Text("👁️")
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text("Look Away")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FSColors.textPrimary)
                Text("Rest your eyes — look 20ft away")
                    .font(.system(size: 11))
                    .foregroundStyle(FSColors.textSecondary)
            }

            Spacer()
        }
        .padding(FSSpacing.md)
        .cardStyle()
    }

    private func saveSession() {
        let session = PomodoroSession(
            focusDuration: engine.focusDuration,
            breakDuration: engine.breakDuration,
            totalSessions: engine.totalSessions
        )
        session.sessionsCompleted = engine.sessionsCompleted
        session.wasCompleted = engine.state == .completed
        session.endedAt = Date()
        modelContext.insert(session)
    }
}
