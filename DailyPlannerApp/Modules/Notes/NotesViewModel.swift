import Foundation
import SwiftData
import SwiftUI
internal import Combine
@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var searchText = ""
    @Published var selectedTags: Set<String> = []
    @Published var sortOption: SortOption = .dateDescending
    
    private var modelContext: ModelContext?
    
    enum SortOption: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case titleAscending = "Title A-Z"
        case titleDescending = "Title Z-A"
    }
    
    var filteredNotes: [Note] {
        var filtered = notes
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Tag filter
        if !selectedTags.isEmpty {
            filtered = filtered.filter { note in
                !Set(note.tags).isDisjoint(with: selectedTags)
            }
        }
        
        // Sort
        switch sortOption {
        case .dateDescending:
            filtered.sort { $0.updatedAt > $1.updatedAt }
        case .dateAscending:
            filtered.sort { $0.updatedAt < $1.updatedAt }
        case .titleAscending:
            filtered.sort { $0.title < $1.title }
        case .titleDescending:
            filtered.sort { $0.title > $1.title }
        }
        
        return filtered
    }
    
    var allTags: [String] {
        let tags = notes.flatMap { $0.tags }
        return Array(Set(tags)).sorted()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadNotes()
    }
    
    func loadNotes() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            notes = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch notes: \(error)")
        }
    }
    
    func createNote() -> Note {
        guard let context = modelContext else { return Note() }
        
        let note = Note()
        context.insert(note)
        
        do {
            try context.save()
            loadNotes()
        } catch {
            print("Failed to create note: \(error)")
        }
        
        return note
    }
    
    func updateNote(_ note: Note, title: String, content: String, tags: [String]) {
        note.title = title
        note.content = content
        note.tags = tags
        note.updatedAt = Date()
        
        do {
            try modelContext?.save()
            loadNotes()
        } catch {
            print("Failed to update note: \(error)")
        }
    }
    
    func deleteNote(_ note: Note) {
        guard let context = modelContext else { return }
        context.delete(note)
        
        do {
            try context.save()
            loadNotes()
        } catch {
            print("Failed to delete note: \(error)")
        }
    }
    
    func toggleFavorite(_ note: Note) {
        note.isFavorite.toggle()
        
        do {
            try modelContext?.save()
            loadNotes()
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }
}

