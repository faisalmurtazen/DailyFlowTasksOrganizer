import Foundation
import SwiftData
import SwiftUI
internal import Combine
@MainActor
class PlannerViewModel: ObservableObject {
    @Published var items: [PlannerItem] = []
    @Published var selectedDate = Date()
    @Published var viewMode: ViewMode = .day
    
    private var modelContext: ModelContext?
    
    enum ViewMode {
        case day, week, month
    }
    
    var filteredItems: [PlannerItem] {
        switch viewMode {
        case .day:
            return items.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        case .week:
            return itemsForWeek()
        case .month:
            return itemsForMonth()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadItems()
    }
    
    func loadItems() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<PlannerItem>(
            sortBy: [SortDescriptor(\.date, order: .forward), SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            items = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch planner items: \(error)")
        }
    }
    
    func createItem(title: String, detail: String, date: Date, startTime: Date?, endTime: Date?, category: String) {
        guard let context = modelContext else { return }
        
        let item = PlannerItem(
            title: title,
            detail: detail,
            date: date.startOfDay(),
            startTime: startTime,
            endTime: endTime,
            category: category
        )
        context.insert(item)
        
        do {
            try context.save()
            loadItems()
        } catch {
            print("Failed to create planner item: \(error)")
        }
    }
    
    func updateItem(_ item: PlannerItem, title: String, detail: String, date: Date, startTime: Date?, endTime: Date?, isAllDay: Bool, category: String) {
        item.title = title
        item.detail = detail
        item.date = date.startOfDay()
        item.startTime = startTime
        item.endTime = endTime
        item.isAllDay = isAllDay
        item.category = category
        
        do {
            try modelContext?.save()
            loadItems()
        } catch {
            print("Failed to update planner item: \(error)")
        }
    }
    
    func toggleCompletion(_ item: PlannerItem) {
        item.isCompleted.toggle()
        
        do {
            try modelContext?.save()
            loadItems()
        } catch {
            print("Failed to toggle completion: \(error)")
        }
    }
    
    func deleteItem(_ item: PlannerItem) {
        guard let context = modelContext else { return }
        context.delete(item)
        
        do {
            try context.save()
            loadItems()
        } catch {
            print("Failed to delete planner item: \(error)")
        }
    }
    
    private func itemsForWeek() -> [PlannerItem] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return []
        }
        
        return items.filter { item in
            item.date >= weekInterval.start && item.date < weekInterval.end
        }
    }
    
    private func itemsForMonth() -> [PlannerItem] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else {
            return []
        }
        
        return items.filter { item in
            item.date >= monthInterval.start && item.date < monthInterval.end
        }
    }
    
    func nextPeriod() {
        let calendar = Calendar.current
        switch viewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }
    
    func previousPeriod() {
        let calendar = Calendar.current
        switch viewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    func goToToday() {
        selectedDate = Date()
    }
}

