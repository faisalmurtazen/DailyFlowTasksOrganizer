import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = NotesViewModel()
    @State private var showingAddNote = false
    @State private var selectedNote: Note?
    @State private var showingSortOptions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    // Tags filter
                    if !viewModel.allTags.isEmpty {
                        tagFilter
                    }
                    
                    // Notes list
                    ScrollView {
                        LazyVStack(spacing: Theme.spacingM) {
                            ForEach(viewModel.filteredNotes) { note in
                                NoteCardView(note: note)
                                    .onTapGesture {
                                        selectedNote = note
                                    }
                                    .contextMenu {
                                        Button(action: { viewModel.toggleFavorite(note) }) {
                                            Label(
                                                note.isFavorite ? "Unfavorite" : "Favorite",
                                                systemImage: note.isFavorite ? "star.slash" : "star"
                                            )
                                        }
                                        
                                        Button(role: .destructive, action: { viewModel.deleteNote(note) }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSortOptions = true }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.defaultAccentTeal)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedNote = viewModel.createNote()
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.defaultAccentTeal)
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .sheet(item: $selectedNote) { note in
                NoteEditorView(note: note, viewModel: viewModel)
            }
            .confirmationDialog("Sort By", isPresented: $showingSortOptions) {
                ForEach(NotesViewModel.SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        viewModel.sortOption = option
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.defaultTextSecondary)
            
            TextField("Search notes...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color.defaultSecondaryBackground)
        .cornerRadius(Theme.cornerRadiusM)
        .padding()
    }
    
    private var tagFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(viewModel.allTags, id: \.self) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: viewModel.selectedTags.contains(tag),
                        onTap: {
                            if viewModel.selectedTags.contains(tag) {
                                viewModel.selectedTags.remove(tag)
                            } else {
                                viewModel.selectedTags.insert(tag)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, Theme.spacingS)
    }
}

struct NoteCardView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .foregroundColor(.defaultTextPrimary)
                
                Spacer()
                
                if note.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.defaultAccentTeal)
                        .font(.caption)
                }
            }
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.body)
                    .foregroundColor(.defaultTextSecondary)
                    .lineLimit(3)
            }
            
            HStack {
                if !note.tags.isEmpty {
                    HStack(spacing: Theme.spacingXS) {
                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.defaultAccentTeal)
                        }
                    }
                }
                
                Spacer()
                
                Text(note.updatedAt.formatted(style: .short))
                    .font(.caption)
                    .foregroundColor(.defaultTextSecondary)
            }
        }
        .padding(Theme.spacingM)
        .background(Color.defaultSecondaryBackground)
        .cornerRadius(Theme.cornerRadiusM)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let note: Note
    let viewModel: NotesViewModel
    
    @State private var title: String
    @State private var content: String
    @State private var tagsString: String
    
    init(note: Note, viewModel: NotesViewModel) {
        self.note = note
        self.viewModel = viewModel
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
        _tagsString = State(initialValue: note.tags.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.spacingM) {
                        TextField("Title", text: $title)
                            .font(.title2)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 300)
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Tags (comma separated)")
                                .font(.caption)
                                .foregroundColor(.defaultTextSecondary)
                            
                            TextField("work, personal, ideas", text: $tagsString)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.defaultSecondaryBackground)
                                .cornerRadius(Theme.cornerRadiusM)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveNote() {
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        viewModel.updateNote(note, title: title, content: content, tags: tags)
    }
}

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("#\(tag)")
                .font(.caption)
                .padding(.horizontal, Theme.spacingM)
                .padding(.vertical, Theme.spacingS)
                .background(isSelected ? Color.defaultAccentTeal : Color.defaultSecondaryBackground)
                .foregroundColor(isSelected ? .white : .defaultTextPrimary)
                .cornerRadius(Theme.cornerRadiusS)
        }
    }
}

