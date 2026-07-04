import SwiftUI

struct TodoRowView: View {
    @Bindable var todo: TodoItem
    var onToggle: () -> Void
    var onDelete: () -> Void

    @State private var isExpanded = false

    private var hasResult: Bool {
        todo.executionResult != nil && !(todo.executionResult ?? "").isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Checkbox
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .stroke(todo.isCompleted ? FSColors.textPrimary : FSColors.textMuted, lineWidth: 1.5)
                            .frame(width: 16, height: 16)
                        if todo.isCompleted {
                            Circle()
                                .fill(FSColors.textPrimary)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)

                // Tappable title area — expands result on click
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(todo.title)
                            .font(.system(size: 13))
                            .foregroundStyle(todo.isCompleted ? FSColors.textMuted : FSColors.textPrimary)
                            .strikethrough(todo.isCompleted, color: FSColors.textMuted)
                            .lineLimit(2)

                        Spacer()

                        // Category badge
                        if let category = todo.category {
                            categoryBadge(category)
                        } else if let tag = todo.tag {
                            tagBadge(tag)
                        }
                    }

                    // Status row for executed/executing tasks
                    if todo.executionStatus != nil {
                        HStack(spacing: 8) {
                            executionStatusView

                            if hasResult {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(FSColors.textMuted)
                                Text(isExpanded ? "Hide output" : "Show output")
                                    .font(.system(size: 10))
                                    .foregroundStyle(FSColors.textMuted)
                            }

                            Spacer()
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard hasResult else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }

                // Delete button
                if todo.isCompleted {
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(FSColors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, FSSpacing.md)
            .padding(.vertical, 11)

            // Expanded result output
            if isExpanded, let result = todo.executionResult {
                Divider()
                    .background(FSColors.bgCardBorder)
                    .padding(.horizontal, FSSpacing.md)

                ScrollView(.vertical, showsIndicators: true) {
                    Text(result)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(FSColors.textSecondary)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(FSSpacing.md)
                }
                .frame(maxHeight: 200)
                .background(FSColors.bgPrimary.opacity(0.5))
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
    }

    // MARK: - Badges

    @ViewBuilder
    private func categoryBadge(_ category: String) -> some View {
        let info = CategoryInfo.from(category)
        HStack(spacing: 4) {
            Image(systemName: info.icon)
                .font(.system(size: 8))
            Text(category)
                .font(.system(size: 10))
        }
        .foregroundStyle(info.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(info.color.opacity(0.12))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func tagBadge(_ tag: String) -> some View {
        Text(tag)
            .font(.system(size: 10))
            .foregroundStyle(FSColors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(FSColors.bgCard)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(FSColors.bgCardBorder, lineWidth: 1))
    }

    // MARK: - Execution Status

    @ViewBuilder
    private var executionStatusView: some View {
        switch todo.executionStatus {
        case "classifying":
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)
                Text("Classifying...")
                    .font(.system(size: 10))
                    .foregroundStyle(FSColors.textMuted)
            }
        case "executing":
            HStack(spacing: 4) {
                PulsingDot()
                Text("Executing...")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
            }
        case "executed":
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                Text("Auto-completed")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.green.opacity(0.8))
        case "failed":
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                Text("Failed")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.red.opacity(0.7))
        default:
            EmptyView()
        }
    }
}

// MARK: - Category Mapping

private enum CategoryInfo {
    case work, focus, entertainment, communication, system, personal, health, unknown

    var color: Color {
        switch self {
        case .work: .blue
        case .focus: .purple
        case .entertainment: .pink
        case .communication: .green
        case .system: .gray
        case .personal: .orange
        case .health: .red
        case .unknown: .gray
        }
    }

    var icon: String {
        switch self {
        case .work: "briefcase.fill"
        case .focus: "brain.head.profile"
        case .entertainment: "play.circle.fill"
        case .communication: "message.fill"
        case .system: "gearshape.fill"
        case .personal: "person.fill"
        case .health: "heart.fill"
        case .unknown: "tag.fill"
        }
    }

    static func from(_ category: String) -> CategoryInfo {
        switch category.lowercased() {
        case "work": .work
        case "focus": .focus
        case "entertainment": .entertainment
        case "communication": .communication
        case "system": .system
        case "personal": .personal
        case "health": .health
        default: .unknown
        }
    }
}

// MARK: - Pulsing Dot Animation

private struct PulsingDot: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(.orange)
            .frame(width: 8, height: 8)
            .scaleEffect(isPulsing ? 1.3 : 0.8)
            .opacity(isPulsing ? 1.0 : 0.5)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
