import Foundation
import SwiftData

@Model
final class ChecklistItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var dueDate: Date?
    var priority: Int
    var subtasks: [SubTask]
    var notes: String?
    
    init(
        id: UUID = UUID(),
        title: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isFavorite: Bool = false,
        dueDate: Date? = nil,
        priority: Int = 0,
        subtasks: [SubTask] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.dueDate = dueDate
        self.priority = priority
        self.subtasks = subtasks
        self.notes = notes
    }
}

struct SubTask: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool
}

