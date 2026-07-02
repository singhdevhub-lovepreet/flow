import SwiftUI
import SwiftData

struct TodosView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.sortOrder) private var todos: [TodoItem]
    @State private var newTodoTitle = ""
    @FocusState private var isTodoFieldFocused: Bool

    private var pendingTodos: [TodoItem] { todos.filter { !$0.isCompleted } }
    private var completedTodos: [TodoItem] { todos.filter { $0.isCompleted } }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Ghost text
            GhostTextView(
                text: "\(pendingTodos.count)",
                font: FSTypography.monoFallbackLarge
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, FSSpacing.screenPadding)
            .padding(.top, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: FSSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tasks")
                            .font(FSTypography.displayFallbackMD)
                            .foregroundStyle(FSColors.textPrimary)
                        Text("\(pendingTodos.count) remaining")
                            .font(FSTypography.uiCaption)
                            .foregroundStyle(FSColors.textSecondary)
                    }

                    // Input bar
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(FSColors.textMuted)

                        TextField("Add a task...", text: $newTodoTitle)
                            .font(.system(size: 13))
                            .foregroundStyle(FSColors.textPrimary)
                            .textFieldStyle(.plain)
                            .focused($isTodoFieldFocused)
                            .onSubmit(addTodo)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(FSColors.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(FSColors.bgCardBorder, lineWidth: 1)
                    )

                    // Pending tasks
                    if !pendingTodos.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(pendingTodos) { todo in
                                TodoRowView(todo: todo, onToggle: {
                                    toggleTodo(todo)
                                }, onDelete: {
                                    deleteTodo(todo)
                                })
                                if todo.id != pendingTodos.last?.id {
                                    Divider()
                                        .background(FSColors.bgCardBorder)
                                        .padding(.horizontal, FSSpacing.md)
                                }
                            }
                        }
                        .cardStyle()
                    }

                    // Completed tasks
                    if !completedTodos.isEmpty {
                        VStack(alignment: .leading, spacing: FSSpacing.sm) {
                            SectionLabel(text: "Completed")

                            VStack(spacing: 0) {
                                ForEach(completedTodos) { todo in
                                    TodoRowView(todo: todo, onToggle: {
                                        toggleTodo(todo)
                                    }, onDelete: {
                                        deleteTodo(todo)
                                    })
                                }
                            }
                            .cardStyle()
                        }
                    }
                }
                .screenPadding()
                .padding(.top, FSSpacing.md)
                .padding(.bottom, FSSpacing.md)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickAddRequested)) { _ in
            // Slight delay to let the panel appear and tab switch before focusing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTodoFieldFocused = true
            }
        }
    }

    private func addTodo() {
        let title = newTodoTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let todo = TodoItem(title: title, sortOrder: (todos.map(\.sortOrder).max() ?? 0) + 1)
        modelContext.insert(todo)
        newTodoTitle = ""
    }

    private func toggleTodo(_ todo: TodoItem) {
        todo.isCompleted.toggle()
        todo.completedAt = todo.isCompleted ? Date() : nil
    }

    private func deleteTodo(_ todo: TodoItem) {
        modelContext.delete(todo)
    }
}
