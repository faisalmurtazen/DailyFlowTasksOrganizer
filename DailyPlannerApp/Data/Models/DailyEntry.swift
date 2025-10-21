import Foundation
import SwiftData

@Model
final class DailyEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var content: String
    var mood: String?
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        content: String = "",
        mood: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.date = date
        self.content = content
        self.mood = mood
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
    }
}

