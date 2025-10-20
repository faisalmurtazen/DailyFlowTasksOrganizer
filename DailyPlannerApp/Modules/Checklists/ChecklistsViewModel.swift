import Foundation
import SwiftData
import SwiftUI
internal import Combine
@MainActor
class ChecklistsViewModel: ObservableObject {
    @Published var checklists: [ChecklistItem] = []
    @Published var showCompleted = true
    @Published var sortByPriority = false
    
    private var modelContext: ModelContext?
    
    var filteredChecklists: [ChecklistItem] {
        var filtered = checklists
        
        if !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        if sortByPriority {
            filtered.sort { $0.priority > $1.priority }
        } else {
            filtered.sort { $0.createdAt > $1.createdAt }
        }
        
        return filtered
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadChecklists()
    }
    
    func loadChecklists() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<ChecklistItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            checklists = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch checklists: \(error)")
        }
    }
    
    func createChecklist(title: String) {
        guard let context = modelContext else { return }
        
        let item = ChecklistItem(title: title)
        context.insert(item)
        
        do {
            try context.save()
            loadChecklists()
        } catch {
            print("Failed to create checklist: \(error)")
        }
    }
    
    func updateChecklist(_ item: ChecklistItem, title: String, notes: String?, priority: Int, dueDate: Date?) {
        item.title = title
        item.notes = notes
        item.priority = priority
        item.dueDate = dueDate
        item.updatedAt = Date()
        
        do {
            try modelContext?.save()
            loadChecklists()
        } catch {
            print("Failed to update checklist: \(error)")
        }
    }
    
    func toggleCompletion(_ item: ChecklistItem) {
        item.isCompleted.toggle()
        item.updatedAt = Date()
        
        do {
            try modelContext?.save()
            loadChecklists()
        } catch {
            print("Failed to toggle completion: \(error)")
        }
    }
    
    func toggleFavorite(_ item: ChecklistItem) {
        item.isFavorite.toggle()
        
        do {
            try modelContext?.save()
            loadChecklists()
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }
    
    func deleteChecklist(_ item: ChecklistItem) {
        guard let context = modelContext else { return }
        context.delete(item)
        
        do {
            try context.save()
            loadChecklists()
        } catch {
            print("Failed to delete checklist: \(error)")
        }
    }
    
    func addSubtask(_ item: ChecklistItem, title: String) {
        let subtask = SubTask(title: title, isCompleted: false)
        item.subtasks.append(subtask)
        item.updatedAt = Date()
        
        do {
            try modelContext?.save()
            loadChecklists()
        } catch {
            print("Failed to add subtask: \(error)")
        }
    }
    
    func toggleSubtask(_ item: ChecklistItem, subtask: SubTask) {
        if let index = item.subtasks.firstIndex(where: { $0.id == subtask.id }) {
            item.subtasks[index].isCompleted.toggle()
            item.updatedAt = Date()
            
            do {
                try modelContext?.save()
                loadChecklists()
            } catch {
                print("Failed to toggle subtask: \(error)")
            }
        }
    }
    
    func deleteSubtask(_ item: ChecklistItem, subtask: SubTask) {
        item.subtasks.removeAll { $0.id == subtask.id }
        item.updatedAt = Date()
        
        do {
            try modelContext?.save()
            loadChecklists()
        } catch {
            print("Failed to delete subtask: \(error)")
        }
    }
}

