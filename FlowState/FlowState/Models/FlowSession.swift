import Foundation
import SwiftData

@Model
final class FlowSession {
    var startedAt: Date
    var endedAt: Date?
    var currentStage: Int
    var completedStages: Int
    var wasCompleted: Bool

    init() {
        self.startedAt = Date()
        self.endedAt = nil
        self.currentStage = 0
        self.completedStages = 0
        self.wasCompleted = false
    }
}
