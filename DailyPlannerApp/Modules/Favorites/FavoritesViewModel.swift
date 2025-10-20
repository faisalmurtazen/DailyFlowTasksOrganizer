import Foundation
import SwiftData
import SwiftUI
internal import Combine
@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favoriteNotes: [Note] = []
    @Published var favoriteChecklists: [ChecklistItem] = []
    @Published var favoriteDailyEntries: [DailyEntry] = []
    @Published var selectedFilter: FilterType = .all
    
    private var modelContext: ModelContext?
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case notes = "Notes"
        case checklists = "Checklists"
        case daily = "Daily"
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadFavorites()
    }
    
    func loadFavorites() {
        guard let context = modelContext else { return }
        
        // Load favorite notes
        let notesDescriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        // Load favorite checklists
        let checklistsDescriptor = FetchDescriptor<ChecklistItem>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        // Load favorite daily entries
        let dailyDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            favoriteNotes = try context.fetch(notesDescriptor)
            favoriteChecklists = try context.fetch(checklistsDescriptor)
            favoriteDailyEntries = try context.fetch(dailyDescriptor)
        } catch {
            print("Failed to fetch favorites: \(error)")
        }
    }
    
    func removeFavoriteNote(_ note: Note) {
        note.isFavorite = false
        saveContext()
    }
    
    func removeFavoriteChecklist(_ checklist: ChecklistItem) {
        checklist.isFavorite = false
        saveContext()
    }
    
    func removeFavoriteDailyEntry(_ entry: DailyEntry) {
        entry.isFavorite = false
        saveContext()
    }
    
    private func saveContext() {
        do {
            try modelContext?.save()
            loadFavorites()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

