import Foundation
import SwiftData
import SwiftUI
internal import Combine
@MainActor
class DailyViewModel: ObservableObject {
    @Published var entries: [DailyEntry] = []
    @Published var selectedDate = Date()
    @Published var currentEntry: DailyEntry?
    @Published var isEditing = false
    @Published var searchText = ""
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadEntries()
    }
    
    func loadEntries() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<DailyEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            entries = try context.fetch(descriptor)
            loadCurrentEntry()
        } catch {
            print("Failed to fetch entries: \(error)")
        }
    }
    
    func loadCurrentEntry() {
        currentEntry = entries.first { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: selectedDate)
        }
    }
    
    func saveEntry(content: String, mood: String?) {
        guard let context = modelContext else { return }
        
        if let existing = currentEntry {
            existing.content = content
            existing.mood = mood
            existing.updatedAt = Date()
        } else {
            let newEntry = DailyEntry(
                date: selectedDate.startOfDay(),
                content: content,
                mood: mood
            )
            context.insert(newEntry)
            currentEntry = newEntry
        }
        
        do {
            try context.save()
            loadEntries()
        } catch {
            print("Failed to save entry: \(error)")
        }
    }
    
    func deleteEntry(_ entry: DailyEntry) {
        guard let context = modelContext else { return }
        context.delete(entry)
        
        do {
            try context.save()
            loadEntries()
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
    
    func toggleFavorite(_ entry: DailyEntry) {
        entry.isFavorite.toggle()
        
        do {
            try modelContext?.save()
            loadEntries()
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        loadCurrentEntry()
    }
}

