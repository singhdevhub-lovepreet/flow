import SwiftUI
import SwiftData
import os

private let log = Logger(subsystem: "com.flowstate.app", category: "TodosView")

struct TodosView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ClaudeService.self) private var claudeService
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

        guard claudeService.isAvailable else {
            log.info("Claude not available, skipping classification for: \"\(title)\"")
            return
        }

        log.info("Starting classification pipeline for: \"\(title)\"")
        Task {
            await classifyAndExecute(todo)
        }
    }

    @MainActor
    private func classifyAndExecute(_ todo: TodoItem) async {
        log.info("[Phase 1] Classifying: \"\(todo.title)\"")
        todo.executionStatus = "classifying"

        do {
            let result = try await claudeService.classify(todo.title)
            todo.category = result.category
            log.info("[Phase 1] Category: \(result.category), executable: \(result.isExecutable)")

            if result.isExecutable,
               let server = result.mcpServer,
               let prompt = result.executionPrompt {
                log.info("[Phase 2] Executing via '\(server)': \"\(prompt)\"")
                todo.executionStatus = "executing"
                let execResult = try await claudeService.execute(prompt, mcpServer: server)
                todo.isCompleted = true
                todo.completedAt = Date()
                todo.executionStatus = "executed"
                todo.executionResult = execResult.result
                StatsService.recordTaskCompleted(in: modelContext)
                log.info("[Phase 2] Auto-completed: \"\(todo.title)\" — result: \(execResult.result?.prefix(200) ?? "(done)")")
            } else {
                todo.executionStatus = nil
                log.info("[Done] Task categorized only (not executable): \"\(todo.title)\"")
            }
        } catch {
            log.error("[Error] Pipeline failed for \"\(todo.title)\": \(error.localizedDescription)")
            todo.executionStatus = todo.executionStatus == "classifying" ? nil : "failed"
        }
    }

    private func toggleTodo(_ todo: TodoItem) {
        todo.isCompleted.toggle()
        todo.completedAt = todo.isCompleted ? Date() : nil

        // Update DailyStats
        if todo.isCompleted {
            StatsService.recordTaskCompleted(in: modelContext)
        } else {
            StatsService.recordTaskUncompleted(in: modelContext)
        }
    }

    private func deleteTodo(_ todo: TodoItem) {
        modelContext.delete(todo)
    }
}
