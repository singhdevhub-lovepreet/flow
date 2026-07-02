import SwiftUI

struct TodoRowView: View {
    @Bindable var todo: TodoItem
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
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
            }
            .buttonStyle(.plain)

            // Title
            Text(todo.title)
                .font(.system(size: 13))
                .foregroundStyle(todo.isCompleted ? FSColors.textMuted : FSColors.textPrimary)
                .strikethrough(todo.isCompleted, color: FSColors.textMuted)
                .lineLimit(1)

            Spacer()

            // Tag
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

            // Delete button (only when completed)
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
    }
}
