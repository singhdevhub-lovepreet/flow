import Foundation
import SwiftData

@Model
final class HabitDefinition {
    var name: String
    var targetValue: Double
    var unit: String
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []

    init(name: String, targetValue: Double, unit: String) {
        self.name = name
        self.targetValue = targetValue
        self.unit = unit
        self.isActive = true
        self.createdAt = Date()
    }
}
