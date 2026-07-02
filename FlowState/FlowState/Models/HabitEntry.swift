import Foundation
import SwiftData

@Model
final class HabitEntry {
    var date: Date
    var currentValue: Double
    var habit: HabitDefinition?

    init(date: Date, currentValue: Double) {
        self.date = date
        self.currentValue = currentValue
    }
}
