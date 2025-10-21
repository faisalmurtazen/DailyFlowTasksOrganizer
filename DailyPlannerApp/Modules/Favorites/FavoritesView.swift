import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = FavoritesViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter
                    filterPicker
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: Theme.spacingM) {
                            if isEmpty {
                                emptyState
                            } else {
                                content
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
    
    private var filterPicker: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            ForEach(FavoritesViewModel.FilterType.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .onChange(of: viewModel.selectedFilter) { _, _ in
            viewModel.loadFavorites()
        }
    }
    
    private var isEmpty: Bool {
        switch viewModel.selectedFilter {
        case .all:
            return viewModel.favoriteNotes.isEmpty &&
                   viewModel.favoriteChecklists.isEmpty &&
                   viewModel.favoriteDailyEntries.isEmpty
        case .notes:
            return viewModel.favoriteNotes.isEmpty
        case .checklists:
            return viewModel.favoriteChecklists.isEmpty
        case .daily:
            return viewModel.favoriteDailyEntries.isEmpty
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "star")
                .font(.system(size: 60))
                .foregroundColor(.defaultTextSecondary)
            
            Text("No favorites yet")
                .font(.headline)
                .foregroundColor(.defaultTextSecondary)
            
            Text("Mark items as favorite to see them here")
                .font(.caption)
                .foregroundColor(.defaultTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.selectedFilter == .all || viewModel.selectedFilter == .notes {
            if !viewModel.favoriteNotes.isEmpty {
                sectionHeader(title: "Notes", count: viewModel.favoriteNotes.count)
                
                ForEach(viewModel.favoriteNotes) { note in
                    FavoriteNoteCard(note: note, onRemove: {
                        viewModel.removeFavoriteNote(note)
                    })
                }
            }
        }
        
        if viewModel.selectedFilter == .all || viewModel.selectedFilter == .checklists {
            if !viewModel.favoriteChecklists.isEmpty {
                sectionHeader(title: "Checklists", count: viewModel.favoriteChecklists.count)
                
                ForEach(viewModel.favoriteChecklists) { checklist in
                    FavoriteChecklistCard(checklist: checklist, onRemove: {
                        viewModel.removeFavoriteChecklist(checklist)
                    })
                }
            }
        }
        
        if viewModel.selectedFilter == .all || viewModel.selectedFilter == .daily {
            if !viewModel.favoriteDailyEntries.isEmpty {
                sectionHeader(title: "Daily Entries", count: viewModel.favoriteDailyEntries.count)
                
                ForEach(viewModel.favoriteDailyEntries) { entry in
                    FavoriteDailyCard(entry: entry, onRemove: {
                        viewModel.removeFavoriteDailyEntry(entry)
                    })
                }
            }
        }
    }
    
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.defaultTextPrimary)
            
            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(.defaultTextSecondary)
            
            Spacer()
        }
        .padding(.top, Theme.spacingM)
    }
}

struct FavoriteNoteCard: View {
    let note: Note
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.spacingM) {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.defaultAccentTeal)
                    
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.headline)
                        .foregroundColor(.defaultTextPrimary)
                }
                
                if !note.content.isEmpty {
                    Text(note.content)
                        .font(.body)
                        .foregroundColor(.defaultTextSecondary)
                        .lineLimit(2)
                }
                
                Text(note.updatedAt.formatted(style: .short))
                    .font(.caption)
                    .foregroundColor(.defaultTextSecondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "star.fill")
                    .foregroundColor(.defaultAccentTeal)
            }
        }
        .padding(Theme.spacingM)
        .background(Color.defaultSecondaryBackground)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

struct FavoriteChecklistCard: View {
    let checklist: ChecklistItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.spacingM) {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                HStack {
                    Image(systemName: checklist.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(checklist.isCompleted ? .defaultAccentTeal : .defaultTextSecondary)
                    
                    Text(checklist.title)
                        .font(.headline)
                        .foregroundColor(.defaultTextPrimary)
                        .strikethrough(checklist.isCompleted)
                }
                
                if !checklist.subtasks.isEmpty {
                    let completed = checklist.subtasks.filter { $0.isCompleted }.count
                    Text("\(completed)/\(checklist.subtasks.count) subtasks completed")
                        .font(.caption)
                        .foregroundColor(.defaultTextSecondary)
                }
                
                if let dueDate = checklist.dueDate {
                    Text("Due: \(dueDate.formatted(style: .short))")
                        .font(.caption)
                        .foregroundColor(dueDate < Date() ? .red : .defaultTextSecondary)
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "star.fill")
                    .foregroundColor(.defaultAccentTeal)
            }
        }
        .padding(Theme.spacingM)
        .background(Color.defaultSecondaryBackground)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

struct FavoriteDailyCard: View {
    let entry: DailyEntry
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.spacingM) {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.defaultAccentTeal)
                    
                    if let mood = entry.mood {
                        Text(mood)
                            .font(.title3)
                    }
                    
                    Text(entry.date.formatted(style: .medium))
                        .font(.headline)
                        .foregroundColor(.defaultTextPrimary)
                }
                
                Text(entry.content)
                    .font(.body)
                    .foregroundColor(.defaultTextSecondary)
                    .lineLimit(3)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "star.fill")
                    .foregroundColor(.defaultAccentTeal)
            }
        }
        .padding(Theme.spacingM)
        .background(Color.defaultSecondaryBackground)
        .cornerRadius(Theme.cornerRadiusM)
    }
}

