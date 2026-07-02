import SwiftUI
import SwiftData

struct FlowModeView: View {
    @Environment(FlowEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: FSSpacing.lg) {
                if engine.isRunning || engine.state == .completed {
                    activeSessionView
                } else {
                    preFlowView
                }
            }
            .screenPadding()
            .padding(.top, FSSpacing.md)
            .padding(.bottom, FSSpacing.md)
        }
    }

    // MARK: - Pre-flow checklist view
    private var preFlowView: some View {
        VStack(alignment: .leading, spacing: FSSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Flow Mode")
                    .font(FSTypography.displayFallbackMD)
                    .foregroundStyle(FSColors.textPrimary)
                Text("Prepare your environment")
                    .font(FSTypography.uiCaption)
                    .foregroundStyle(FSColors.textSecondary)
            }

            // Breathing circle preview
            BreathingCircleView(rate: 6.0, isAnimating: true)
                .frame(maxWidth: .infinity)
                .frame(height: 160)

            // Checklist
            VStack(alignment: .leading, spacing: FSSpacing.sm) {
                SectionLabel(text: "Pre-Flow Checklist")

                VStack(spacing: 0) {
                    ForEach(engine.checklist) { item in
                        checklistRow(item)
                        if item.id != engine.checklist.last?.id {
                            Divider()
                                .background(FSColors.bgCardBorder)
                                .padding(.horizontal, FSSpacing.md)
                        }
                    }
                }
                .cardStyle()
            }

            CTAButton(title: "Begin Flow") {
                engine.start()
            }
        }
    }

    // MARK: - Active session view
    private var activeSessionView: some View {
        VStack(spacing: FSSpacing.lg) {
            // Stage label
            Text(engine.state.label)
                .font(FSTypography.uiLabel)
                .foregroundStyle(FSColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            // Breathing circle
            BreathingCircleView(
                rate: engine.breathingRate,
                isAnimating: engine.isRunning
            )
            .frame(height: 180)

            // Timer
            Text(engine.formattedTime(engine.state.remaining))
                .font(FSTypography.monoFallbackTimer)
                .foregroundStyle(FSColors.textPrimary)
                .monospacedDigit()

            // Stage dots
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    let stageNames = ["Prepare", "Focus", "Release", "Rest"]
                    VStack(spacing: 4) {
                        Circle()
                            .fill(index <= engine.state.stageIndex ? FSColors.textPrimary : FSColors.textMuted)
                            .frame(width: 8, height: 8)
                        Text(stageNames[index])
                            .font(.system(size: 9))
                            .foregroundStyle(
                                index == engine.state.stageIndex ? FSColors.textPrimary : FSColors.textMuted
                            )
                    }
                }
            }

            // Controls
            if engine.state == .completed {
                VStack(spacing: FSSpacing.sm) {
                    Text("Session complete")
                        .font(FSTypography.uiBody)
                        .foregroundStyle(FSColors.textSecondary)

                    CTAButton(title: "Done") {
                        saveSession()
                        engine.stop()
                    }
                }
            } else {
                CTAButton(title: "End Session", isPrimary: false) {
                    saveSession()
                    engine.stop()
                }
            }
        }
    }

    private func checklistRow(_ item: ChecklistItem) -> some View {
        Button {
            engine.toggleChecklistItem(item)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(item.isChecked ? FSColors.textPrimary : FSColors.textMuted, lineWidth: 1.5)
                        .frame(width: 16, height: 16)

                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(FSColors.textPrimary)
                    }
                }

                Text(item.title)
                    .font(.system(size: 13))
                    .foregroundStyle(item.isChecked ? FSColors.textPrimary : FSColors.textSecondary)

                Spacer()
            }
            .padding(.horizontal, FSSpacing.md)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func saveSession() {
        let session = FlowSession()
        session.currentStage = engine.state.stageIndex
        session.completedStages = max(0, engine.state.stageIndex)
        session.wasCompleted = engine.state == .completed
        session.endedAt = Date()
        modelContext.insert(session)
    }
}
