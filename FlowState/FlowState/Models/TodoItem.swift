import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String
    var isCompleted: Bool
    var tag: String?
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int

    init(title: String, tag: String? = nil, sortOrder: Int = 0) {
        self.title = title
        self.isCompleted = false
        self.tag = tag
        self.createdAt = Date()
        self.completedAt = nil
        self.sortOrder = sortOrder
    }
}
