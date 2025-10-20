import Foundation
import SwiftData

@Model
final class PlannerItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var isAllDay: Bool
    var isCompleted: Bool
    var category: String
    var color: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String = "",
        detail: String = "",
        date: Date = Date(),
        startTime: Date? = nil,
        endTime: Date? = nil,
        isAllDay: Bool = false,
        isCompleted: Bool = false,
        category: String = "general",
        color: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.isAllDay = isAllDay
        self.isCompleted = isCompleted
        self.category = category
        self.color = color
        self.createdAt = createdAt
    }
}

